module Atomy
  class MethodPatterns
    attr_accessor :receiver, :required, :defaults, :splat, :block

    def initialize(receiver, required = [],
                   defaults = [], splat = nil, block = nil)
      @receiver = receiver
      @required = required
      @defaults = defaults
      @splat = splat
      @block = block
    end

    def ==(b)
      equal?(b) or \
        @receiver == b.receiver and \
        @required == b.required and \
        @defaults == b.defaults and \
        @splat == b.splat and \
        @block == b.block
    end

    def size
      @required.size + @defaults.size +
        (@splat ? 1 : 0) + (@block ? 1 : 0)
    end
  end

  # the ivar where method branches are stored
  def self.methods_var(name)
    :"@atomy::#{name}"
  end

  # stores the "real" sender; used for things like "super"
  # where we want to keep the original for namespace checks
  def self.sender_var
    :"@atomy::sender"
  end

  # should we bother matching self?
  #
  # some things, like Constant patterns, indicate that
  # it'll always match
  def self.should_match_self?(pat)
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
  def self.get_sender_scope(g)
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

  # build all of the method branches into one CompiledMethod
  def self.build_method(name, branches, all_for_one = false,
                        file = :dynamic_build, line = 1)
    g = Rubinius::Generator.new
    g.name = name.to_sym
    g.file = file.to_sym
    g.set_line Integer(line)

    done = g.new_label
    mismatch = g.new_label

    g.push_state Rubinius::AST::ClosedScope.new(line)

    g.state.push_name name

    g.state.scope.new_local(:arguments).reference

    g.splat_index = 0
    g.total_args = 0
    g.required_args = 0

    g.push_self

    # push the namespaced checks first
    branches.each do |provided, methods|
      next unless provided

      skip = g.new_label

      get_sender_scope(g)
      g.send :module, 0
      g.push_literal provided
      g.send :using?, 1
      g.gif skip

      build_methods(g, methods, done, all_for_one)

      skip.set!
    end

    # try the bottom namespace after the others
    if bottom = branches[nil] and not bottom.empty?
      build_methods(g, bottom, done, all_for_one)
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

    if branches[nil].empty?
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

    g.package Rubinius::CompiledMethod
  end

  # build all the method branches, assumed to be from the
  # same namespace
  def self.build_methods(g, methods, done, all_for_one)
    methods.each do |pats, meth, scope|
      recv = pats.receiver
      reqs = pats.required
      defs = pats.defaults
      splat = pats.splat
      block = pats.block

      skip = g.new_label
      argmis = g.new_label
      argmis2 = g.new_label

      if reqs.size
        g.passed_arg(reqs.size - 1)
        g.gif skip
      end

      unless all_for_one
        g.push_cpath_top
        g.find_const :Rubinius
        g.find_const :CompiledMethod
        g.send :current, 0
        g.push_literal scope
        g.send :"scope=", 1
        g.pop
      end

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

      meth.compile(g)
      g.goto done

      argmis2.set!
      g.pop

      argmis.set!
      g.pop

      skip.set!
    end
  end

  # StaticScope equivalency test
  def self.equal_scope?(a, b)
    return a == b unless a and b

    a.module == b.module and \
      equal_scope?(a.parent, b.parent)
  end

  # build a method from the given branches and add it to
  # the target
  def self.add_method(target, name, branches,
                      static_scope, visibility = :public,
                      file = :dynamic_add, line = 1, defn = false)
    all_for_one = true
    scope = nil
    branches.each_value do |ms|
      ms.each do |_, _, s|
        unless equal_scope?(s, scope ||= s)
          all_for_one = false
          break
        end
      end

      break unless all_for_one
    end

    cm = build_method(name, branches, all_for_one, file, line)

    if all_for_one
      cm.scope = scope
    else
      cm.scope = Rubinius::StaticScope.new(Object)
    end

    if defn and not Thread.current[:atomy_provide_in]
      Rubinius.add_defn_method name, cm, static_scope, visibility
    else
      target = Object if defn
      Rubinius.add_method name, cm, target, visibility
    end
  end

  # define a new method branch
  def self.define_method(target, name, patterns, body,
                         static_scope, visibility = :public,
                         file = :dynamic_define, line = 1, defn = false)
    provided = Thread.current[:atomy_provide_in]
    method = [patterns, body, static_scope]
    methods = target.instance_variable_get(methods_var(name))

    if methods
      insert_method(method, methods[provided])
    else
      branches = Hash.new { |h, k| h[k] = [] }
      branches[provided] << method
      methods = target.instance_variable_set(
        methods_var(name),
        branches
      )
    end

    add_method(target, name, methods, static_scope,
               visibility, file, line, defn)
  end

  # compare one method's precision to another
  def self.compare(xs, ys)
    return 1 if xs.size > ys.size
    return -1 if xs.size < ys.size

    total = xs.receiver <=> ys.receiver

    xs.required.zip(ys.required) do |x, y|
      total += x <=> y unless y.nil?
    end

    xs.defaults.zip(ys.defaults) do |x, y|
      total += x <=> y unless y.nil?
    end

    if xs.splat and ys.splat
      total += xs.splat <=> ys.splat
    end

    if xs.block and ys.block
      total += xs.block <=> ys.block
    end

    total <=> 0
  end

  # will two patterns (and namespaces) always match the
  # same things?
  def self.equivalent?(xs, ys)
    return false unless xs.size == ys.size

    return false unless xs.receiver =~ ys.receiver

    xs.required.zip(ys.required) do |x, y|
      return false unless x =~ y
    end

    xs.defaults.zip(ys.defaults) do |x, y|
      return false unless x =~ y
    end

    return false unless xs.splat =~ ys.splat
    return false unless xs.block =~ ys.block

    true
  end

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
  def self.insert_method(new, branches)
    unless new[0].receiver.respond_to?(:<=>)
      return branches.unshift(new)
    end

    if branches.instance_variable_get(:"@sorted")
      nps, nb, _ = new
      branches.each_with_index do |branch, i|
        ps, b, _ = branch

        case compare(nps, ps)
        when 1
          return branches.insert(i, new)
        when 0
          if equivalent?(nps, ps)
            branches[i] = new
            return branches
          end
        end
      end

      branches << new
    else
      # this is needed because we define methods before <=> is
      # defined, so sort it once we have that
      branches.unshift(new).sort! do |b, a|
        compare(a[0], b[0])
      end

      branches.instance_variable_set(:"@sorted", true)

      branches
    end
  end
end
