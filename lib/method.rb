module Atomy
  class MethodPatterns
    attr_accessor :receiver, :required, :defaults, :splat, :block

    def initialize(receiver, required = [], defaults = [], splat = nil, block = nil)
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
      @required.size + @defaults.size + (@splat ? 1 : 0) + (@block ? 1 : 0)
    end
  end

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

  def self.get_sender_scope(g)
    done = g.new_label

    g.push_rubinius
    g.find_const :StaticScope
    g.send :of_sender, 0
    g.dup
    g.push_literal :"@atomy:sender"
    g.send :instance_variable_get, 1
    g.dup
    g.gif done

    g.swap

    done.set!
    g.pop
  end

  def self.build_method(name, branches, file = :dynamic_build, line = 1)
    g = Rubinius::Generator.new
    g.name = name.to_sym
    g.file = file.to_sym
    g.set_line Integer(line)

    done = g.new_label
    mismatch = g.new_label

    g.push_state Rubinius::AST::ClosedScope.new(line)

    g.state.push_name name

    total = 0
    min_reqs = nil
    reqs = 0
    defs = 0
    splatted = false

    # grouped methods by the namespace they're provided in
    by_namespace = Hash.new { |h, k| h[k] = [] }

    # determine locals and the required/default/total args
    branches.each do |pats, meth, provided, scope|
      min_reqs ||= pats.required.size
      min_reqs = [min_reqs, pats.required.size].min
      reqs = [reqs, pats.required.size].max
      defs = [defs, pats.defaults.size].max
      total = [reqs + defs, total].max

      splatted = true if pats.splat

      by_namespace[provided] << [pats, meth, scope]
    end

    if splatted
      g.splat_index = reqs + defs
    end

    total.times do |n|
      g.state.scope.new_local(:"arg:#{n}").reference
    end

    g.total_args = total
    g.required_args = min_reqs

    g.push_self

    # push the namespaced checks first
    by_namespace.each do |provided, methods|
      next unless provided

      skip = g.new_label

      get_sender_scope(g)
      g.send :module, 0
      g.push_literal provided
      g.send :using?, 1
      g.gif skip

      build_methods(g, methods, done, min_reqs)

      skip.set!
    end

    # try the bottom namespace after the others
    if bottom = by_namespace[nil] and not bottom.empty?
      build_methods(g, bottom, done, min_reqs)
    end

    # call super. note that we keep the original sender's static scope for use
    # in namespace checks
    unless name == :initialize
      g.invoke_primitive :vm_check_super_callable, 0
      g.gif mismatch

      g.push_scope
      g.push_literal :"@atomy:sender"
      get_sender_scope(g)
      g.send :instance_variable_set, 2
      g.pop

      g.push_block
      if g.state.super?
        g.zsuper g.state.super.name
      else
        g.zsuper nil
      end

      g.push_scope
      g.push_literal :"@atomy:sender"
      g.push_nil
      g.send :instance_variable_set, 2
      g.pop

      g.goto done
    end

    # no method branches matched; fail
    mismatch.set!
    g.push_self
    g.push_cpath_top
    # if all the definitions are local to a namespace, act like the method
    # doesn't even exist
    if by_namespace[nil].empty?
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

  def self.build_methods(g, methods, done, min_reqs)
    methods.each do |pats, meth, scope|
      recv = pats.receiver
      reqs = pats.required
      defs = pats.defaults
      splat = pats.splat
      block = pats.block

      skip = g.new_label
      argmis = g.new_label

      if reqs.size > min_reqs
        g.passed_arg(reqs.size - 1)
        g.gif skip
      end

      g.push_variables
      g.send :method, 0
      g.push_literal scope
      g.send :"scope=", 1
      g.pop

      if should_match_self?(recv)
        g.dup
        recv.matches_self?(g)
        g.gif skip
      end

      if splat
        g.push_local(g.splat_index)
        g.send :to_list, 0
        splat.pattern.deconstruct(g)
      end

      if recv.bindings > 0
        g.dup
        recv.deconstruct(g)
      end

      if block
        g.push_block_arg
        block.deconstruct(g)
      end

      reqs.each_with_index do |a, i|
        next if a.wildcard? && a.bindings == 0

        g.push_local(i)

        if a.bindings > 0
          unless a.wildcard?
            g.dup
            a.matches?(g)
            g.gif argmis
          end
          a.deconstruct(g)
        else
          a.matches?(g)
          g.gif skip
        end
      end

      defs.each_with_index do |d, i|
        passed = g.new_label
        decons = g.new_label

        num = reqs.size + i
        g.passed_arg num
        g.git passed

        d.default.compile(g)
        g.set_local num
        g.goto decons

        passed.set!
        g.push_local num

        decons.set!
        d.deconstruct(g)
      end

      meth.compile(g)
      g.goto done

      argmis.set!
      g.pop

      skip.set!
    end
  end

  def self.add_method(target, name, branches, static_scope, visibility = :public, file = :dynamic_add, line = 1, defn = false)
    cm = build_method(name, branches, file, line)
    cm.scope = Rubinius::StaticScope.new(Object)

    if defn and not Thread.current[:atomy_provide_in]
      Rubinius.add_defn_method name, cm, static_scope, visibility
    else
      Rubinius.add_method name, cm, defn ? Object : target, visibility
    end
  end

  def self.define_method(target, name, patterns, body, static_scope, visibility = :public, file = :dynamic_define, line = 1)
    method = [patterns, body, nil, static_scope]
    methods = target.instance_variable_get(:"@atomy::#{name}")

    if methods
      insert_method(method, methods)
    else
      methods = target.instance_variable_set(:"@atomy::#{name}", [method])
    end

    add_method(target, name, methods, static_scope, visibility, file, line)
  end

  def self.compare(xs, ys, nn, n)
    return 1 if xs.size > ys.size
    return -1 if xs.size < ys.size
    return 1 if nn and not n
    return -1 if not nn and n

    total = xs.receiver <=> ys.receiver

    xs.required.zip(ys.required) do |x, y|
      total += x <=> y unless y.nil?
    end

    xs.defaults.zip(ys.defaults) do |x, y|
      total += x <=> y unless y.nil?
    end

    # TODO: bother with this?
    #if xs.splat and ys.splat
      #total += xs.splat <=> ys.splat
    #end

    total <=> 0
  end

  def self.equivalent?(xs, ys, xn, yn)
    return false unless xn == yn
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

  # this should mutate branches, so I don't have to call
  # instance_variable_set
  def self.insert_method(new, branches)
    if new[0].receiver.respond_to?(:<=>)
      if branches.instance_variable_get(:"@sorted")
        nps, nb, nn = new
        branches.each_with_index do |branch, i|
          ps, b, n = branch

          case compare(nps, ps, nn, n)
          when 1
            return branches.insert(i, new)
          when 0
            if equivalent?(nps, ps, nn, n)
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
          compare(a[0], b[0], a[2], b[2])
        end

        branches.instance_variable_set(:"@sorted", true)

        branches
      end
    else
      branches.unshift(new)
    end
  end
end
