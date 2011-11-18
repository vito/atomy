module Atomy
  METHODS = Hash.new { |h, k| h[k] = {} }

  # TODO: visibility?
  class Branch
    attr_accessor :receiver, :executable, :required, :defaults,
                  :splat, :block, :file, :name

    def initialize(receiver, executable, required = [],
                   defaults = [], splat = nil, block = nil,
                   file = :dynamic)
      @receiver = receiver
      @executable = executable
      @required = required
      @defaults = defaults
      @splat = splat
      @block = block
      @file = file
    end

    def ==(b)
      equal?(b) or \
        @receiver == b.receiver and \
        @executable == b.executable and \
        @required == b.required and \
        @defaults == b.defaults and \
        @splat == b.splat and \
        @block == b.block
    end

    def total_args
      @required.size + @defaults.size
    end

    # compare one method's precision to another
    def <=>(other)
      return 1 if total_args > other.total_args
      return -1 if total_args < other.total_args

      total = @receiver <=> other.receiver

      @required.zip(other.required) do |x, y|
        total += x <=> y unless y.nil?
      end

      @defaults.zip(other.defaults) do |x, y|
        total += x <=> y unless y.nil?
      end

      if @splat and other.splat
        total += @splat <=> other.splat
      end

      if @block and other.block
        total += @block <=> other.block
      end

      total <=> 0
    end

    # will two patterns (and namespaces) always match the
    # same things?
    def =~(other)
      return false unless total_args == other.total_args

      return false unless @receiver =~ other.receiver

      @required.zip(other.required) do |x, y|
        return false unless x =~ y
      end

      @defaults.zip(other.defaults) do |x, y|
        return false unless x =~ y
      end

      return false unless @splat =~ other.splat
      return false unless @block =~ other.block

      true
    end
  end

  class Method
    include Enumerable

    def initialize(name)
      @name = name
      @branches = Hash.new { |h, k| h[k] = [] }
      @sorted = false
    end

    def new_name
      :"#{@name}:#{Macro::Environment.salt!}"
    end

    def add(branch, provided_in = nil)
      insert(branch, @branches[provided_in])
      branch.name = new_name
      nil
    end

    def sorted?
      @sorted
    end

    def sort!
      @branches.each_value do |v|
        v.sort! { |x, y| y <=> x }
      end
      @sorted = true
    end

    # TODO: delegate to @branches
    def each(&blk)
      @branches.each(&blk)
    end

    def [](ns)
      @branches[ns]
    end

    def build
      g = Rubinius::Generator.new
      g.name = @name
      g.file = :dynamic
      g.set_line 0

      done = g.new_label
      mismatch = g.new_label

      g.push_state Rubinius::AST::ClosedScope.new(0)

      g.state.push_name @name

      g.state.scope.new_local(:arguments).reference

      g.splat_index = 0
      g.total_args = 0
      g.required_args = 0

      # TODO: this kills the performance.
      g.push_rubinius
      g.find_const :CompiledMethod
      g.send :current, 0
      get_sender_scope(g)
      g.send :"scope=", 1
      g.pop

      # push the namespaced checks first
      @branches.each do |provided, methods|
        next unless provided

        skip = g.new_label

        get_sender_scope(g)
        g.send :module, 0
        g.push_literal provided
        g.send :using?, 1
        g.gif skip

        build_methods(g, methods, done)

        skip.set!
      end

      # try the bottom namespace after the others
      if bottom = @branches[nil] and not bottom.empty?
        build_methods(g, bottom, done)
      end

      # call super. note that we keep the original sender's static
      # scope for use in namespace checks
      unless @name == :initialize
        g.invoke_primitive :vm_check_super_callable, 0
        g.gif mismatch

        g.push_block
        if g.state.super?
          g.zsuper g.state.super.name
        else
          g.zsuper nil
        end

        g.goto done
      end

      # no method branches matched; fail
      mismatch.set!
      g.push_self
      g.push_cpath_top

      if @branches[nil].empty?
        g.find_const :NoMethodError
        g.push_literal "unexposed method `"
        g.push_literal @name.to_s
        g.push_literal "' called on an instance of "
        g.push_self
        g.send :class, 0
        g.send :to_s, 0
        g.push_literal "."
        g.string_build 5
      else
        g.find_const :Atomy
        g.find_const :MethodFail
        g.push_literal @name
      end

      g.send :new, 1
      g.allow_private
      g.send :raise, 1

      # successfully evaluated a branch
      done.set!

      g.state.pop_name

      g.ret
      g.close

      g.local_names = g.state.scope.local_names
      g.local_count = g.state.scope.local_count

      g.pop_state
      g.use_detected
      g.encode

      cm = g.package Rubinius::CompiledMethod

      cm.scope = Rubinius::StaticScope.new(Object)

      cm
    end

  private

    # insert method `new` into the list of branches
    #
    # if <=> isn't defined, we can't compare precision, so
    # just unshift it
    #
    # if it is defined, but the branches aren't sorted, sort them
    #
    # if it is defined, and the branches are already sorted, insert
    # it in the proper order
    #
    # during insertion, branches with equivalent patterns will
    # be replaced
    def insert(new, branches)
      unless new.receiver.respond_to?(:<=>)
        return branches.unshift(new)
      end

      if sorted?
        branches.each_with_index do |branch, i|
          case new <=> branch
          when 1
            return branches.insert(i, new)
          when 0
            if new =~ branch
              branches[i] = new
              return branches
            end
          end
        end

        branches << new
      else
        # this is needed because we define methods before <=> is
        # defined, so sort it once we have that
        branches.unshift(new)

        sort!

        branches
      end
    end

    # build all the method branches, assumed to be from the
    # same namespace
    def build_methods(g, methods, done)
      methods.each do |meth|
        recv = meth.receiver
        reqs = meth.required
        defs = meth.defaults
        splat = meth.splat
        block = meth.block

        has_args = meth.total_args > 0

        skip = g.new_label
        argmis = g.new_label

        if reqs.size > 0
          g.passed_arg(reqs.size - 1)
          g.gif skip
        end

        if should_match_self?(recv)
          g.push_self
          recv.matches_self?(g)
          g.gif skip
        end

        if has_args
          g.push_local 0

          unless defs.empty?
            no_stretch = g.new_label

            g.passed_arg(meth.total_args - 1)
            g.git no_stretch

            g.dup
            g.push_int(meth.total_args - 1)
            g.push_nil
            g.send :[]=, 2
            g.pop

            no_stretch.set!
          end

          reqs.each_with_index do |a, i|
            g.shift_array

            if a.wildcard?
              g.pop
            else
              a.matches?(g)
              g.gif argmis
            end
          end

          defs.each_with_index do |d, i|
            have_value = g.new_label

            g.shift_array

            num = reqs.size + i
            g.passed_arg num
            g.git have_value

            g.pop
            g.push_local 0
            g.push_int num
            d.default.compile(g)
            g.send :[]=, 2

            have_value.set!
            d.matches?(g)
            g.gif argmis
          end

          if splat and s = splat.pattern
            g.send :to_list, 0
            s.matches?(g)
            g.gif skip
          else
            g.pop
          end
        end

        g.push_self
        if has_args or splat
          g.push_local 0
          g.push_block
          g.send_with_splat meth.name, 0, true
        elsif block
          g.push_block
          g.send_with_block meth.name, 0, true
        else
          g.send_vcall meth.name
        end
        g.goto done

        argmis.set!
        g.pop if has_args

        skip.set!
      end
    end

    # should we bother matching self?
    #
    # some things, like Constant patterns, indicate that
    # it'll always match
    def should_match_self?(pat)
      case pat
      when Patterns::Match
        pat.value != :self
      when Patterns::Constant
        false
      when Patterns::Named
        should_match_self?(pat.pattern)
      else
        !pat.wildcard?
      end
    end

    # get the "actual" sender; either StaticScope.of_sender
    # or VariableScope.of_sender's sender ivar if it's set
    def get_sender_scope(g)
      g.push_rubinius
      g.find_const :StaticScope
      g.send :of_sender, 0
    end

    # StaticScope equivalency test
    def equal_scope?(a, b)
      return a == b unless a and b

      a.module == b.module and \
        equal_scope?(a.parent, b.parent)
    end

    # stores the "real" sender; used for things like "super"
    # where we want to keep the original for namespace checks
    def sender_var
      :"@atomy::sender"
    end
  end

  # build a method from the given branches and add it to
  # the target
  def self.add_method(target, name, method, visibility = :public)
    cm = method.build

    Rubinius.add_method name, cm, target, visibility
  end

  # define a new method branch
  def self.define_branch(target, name, branch, visibility, scope, defn)
    provided = Thread.current[:atomy_provide_in]
    methods = METHODS[target]

    if method = methods[name]
      method.add(branch, provided)
    else
      method = Method.new(name)
      method.add(branch, provided)
      methods[name] = method
    end

    target = Object if defn and Thread.current[:atomy_provide_in]

    if defn and not Thread.current[:atomy_provide_in]
      Rubinius.add_defn_method branch.name, branch.executable, scope, visibility
    else
      Rubinius.add_method branch.name, branch.executable, target, visibility
    end

    add_method(target, name, method, visibility)
  end
end
