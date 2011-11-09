module Atomy
  class Method
    attr_accessor :receiver, :body, :scope, :required, :defaults,
                  :splat, :block, :file

    def initialize(receiver, body, scope, required = [],
                   defaults = [], splat = nil, block = nil,
                   file = :dynamic)
      @receiver = receiver
      @body = body
      @scope = scope
      @required = required
      @defaults = defaults
      @splat = splat
      @block = block
      @file = file
    end

    def ==(b)
      equal?(b) or \
        @receiver == b.receiver and \
        @body == b.body and \
        @scope == b.scope and \
        @required == b.required and \
        @defaults == b.defaults and \
        @splat == b.splat and \
        @block == b.block
    end

    def size
      @required.size + @defaults.size +
        (@splat ? 1 : 0) + (@block ? 1 : 0)
    end

    # compare one method's precision to another
    def <=>(other)
      return 1 if size > other.size
      return -1 if size < other.size

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
      return false unless size == other.size

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

  class MethodBranches
    include Enumerable

    attr_reader :scopes

    def initialize
      @branches = Hash.new { |h, k| h[k] = [] }

      # are we sorted yet?
      @sorted = false
    end

    def add(branch, provided_in = nil)
      insert(branch, @branches[provided_in])

      nil
    end

    def sorted?
      @sorted
    end

    def sort!
      @branches.each_value(&:sort!)

      @sorted = true
    end

    def each(&blk)
      @branches.each(&blk)
    end

    def [](ns)
      @branches[ns]
    end

    def build(name)
      g = Rubinius::Generator.new
      g.name = name.to_sym
      g.file = :dynamic
      g.set_line 0

      done = g.new_label
      mismatch = g.new_label

      g.push_state Rubinius::AST::ClosedScope.new(0)

      g.state.push_name name

      g.state.scope.new_local(:arguments).reference

      g.splat_index = 0
      g.total_args = 0
      g.required_args = 0

      g.push_self

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
      unless name == :initialize
        g.invoke_primitive :vm_check_super_callable, 0
        g.gif mismatch

        g.push_variables
        g.push_literal sender_var
        get_sender_scope(g)
        g.send :instance_variable_set, 2
        g.pop

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
        g.push_literal name.to_s
        g.push_literal "' called on an instance of "
        g.push_self
        g.send :class, 0
        g.send :to_s, 0
        g.push_literal "."
        g.string_build 5
      else
        g.find_const :Atomy
        g.find_const :MethodFail
        g.push_literal name
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
    # if it is defined, but the list isn't sorted, sort it
    #
    # if it is defined, and the list is already sorted, insert
    # it in the proper location with respect to precision
    #
    # during insertion, methods with equivalent patterns will
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
        body = meth.body
        scope = meth.scope

        skip = g.new_label
        argmis = g.new_label
        argmis2 = g.new_label

        if reqs.size
          g.passed_arg(reqs.size - 1)
          g.gif skip
        end

        g.push_rubinius
        g.find_const :CompiledMethod
        g.send :current, 0
        g.push_literal scope
        g.send :"scope=", 1
        g.pop

        if should_match_self?(recv)
          g.dup
          recv.matches_self?(g)
          g.gif skip
        end

        if recv.bindings > 0
          g.dup
          recv.deconstruct(g)
        end

        if block
          g.push_block_arg
          block.deconstruct(g)
        end

        g.push_local 0

        reqs.each_with_index do |a, i|
          g.shift_array

          if a.bindings > 0
            unless a.wildcard?
              g.dup
              a.matches?(g)
              g.gif argmis2
            end

            a.deconstruct(g)
          elsif a.wildcard?
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
          unless d.wildcard?
            g.dup
            d.matches?(g)
            g.gif argmis2
          end
          d.deconstruct(g)
        end

        g.pop

        if splat and s = splat.pattern
          g.push_local 0
          (reqs.size + defs.size).times do
            g.shift_array
            g.pop
          end

          g.send :to_list, 0
          unless s.wildcard?
            g.dup
            s.matches?(g)
            g.gif argmis
          end
          s.deconstruct(g)
        end

        body.compile(g)
        g.goto done

        argmis2.set!
        g.pop

        argmis.set!
        g.pop

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
      done = g.new_label

      g.push_rubinius
      g.find_const :StaticScope
      g.send :of_sender, 0
      g.push_rubinius
      g.find_const :VariableScope
      g.send :of_sender, 0
      g.push_literal sender_var
      g.send :instance_variable_get, 1
      g.dup
      g.gif done

      g.swap

      done.set!
      g.pop
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

  # the ivar where method branches are stored
  def self.methods_var(name)
    :"@atomy::#{name}"
  end

  # build a method from the given branches and add it to
  # the target
  def self.add_method(target, name, branches,
                      static_scope, visibility = :public, defn = false)
    cm = branches.build(name)

    if defn and not Thread.current[:atomy_provide_in]
      Rubinius.add_defn_method name, cm, static_scope, visibility
    else
      target = Object if defn
      Rubinius.add_method name, cm, target, visibility
    end
  end

  # define a new method branch
  def self.define_method(target, name, method, visibility = :public, defn = false)
    provided = Thread.current[:atomy_provide_in]
    branches = target.instance_variable_get(methods_var(name))

    if branches
      branches.add(method, provided)
    else
      branches = MethodBranches.new
      branches.add(method, provided)
      target.instance_variable_set(methods_var(name), branches)
    end

    add_method(target, name, branches, method.scope, visibility, defn)
  end
end
