module Atomy
  def self.segments(args)
    req = []
    dfs = []
    spl = nil
    blk = nil
    args.each do |a|
      case a
      when Patterns::BlockPass
        blk = a
      when Patterns::Splat
        spl = a
      when Patterns::Default
        dfs << a
      else
        req << a
      end
    end
    [req, dfs, spl, blk]
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
    names = []
    splatted = false

    resolved = branches.collect do |pats, meth, provided|
      segs = segments(pats[1])

      min_reqs ||= segs[0].size
      min_reqs = [min_reqs, segs[0].size].min
      reqs = [reqs, segs[0].size].max
      defs = [defs, segs[1].size].max
      total = [reqs + defs, total].max

      names += pats[0].local_names
      pats[1].each do |p|
        names += p.local_names
      end

      splatted = true if segs[2]

      [pats[0], segs, meth, provided]
    end

    names.uniq!

    if splatted
      g.splat_index = reqs + defs
    end

    total.times do |n|
      names.unshift("arg:" + n.to_s)
    end

    locals = {}
    names.each do |n|
      locals[n] = g.state.scope.new_local(n).reference
    end

    g.local_names = names
    g.total_args = total
    g.required_args = min_reqs
    g.local_count = total + g.local_names.size

    g.push_self
    resolved.each do |recv, (reqs, defs, splat, block), meth, provided|
      skip = g.new_label
      argmis = g.new_label

      if reqs.size > min_reqs
        g.passed_arg(reqs.size - 1)
        g.gif skip
      end

      if provided
        g.push_cpath_top
        g.find_const :Atomy
        get_sender_scope(g)
        # g.debug "[#{name}] sender"
        g.send :module, 0
        g.push_literal provided
        # g.debug "[#{name}] provided from"
        g.send :using?, 2
        # g.debug "[#{name}] using?"
        g.gif skip
      end

      if should_match_self?(recv)
        g.dup
        recv.matches_self?(g)
        g.gif skip
      end

      if splat
        g.push_local(g.splat_index)
        splat.pattern.deconstruct(g)
      end

      if recv.bindings > 0
        g.dup
        recv.deconstruct(g, locals)
      end

      if block
        g.push_block_arg
        block.deconstruct(g, locals)
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
          a.deconstruct(g, locals)
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

    mismatch.set!
    g.push_self
    g.push_cpath_top
    g.find_const :Atomy
    g.find_const :MethodFail
    g.push_literal name
    g.send :new, 1
    g.allow_private
    g.send :raise, 1

    done.set!
    g.state.pop_name
    g.ret
    g.close
    g.pop_state
    g.use_detected
    g.encode

    g.package Rubinius::CompiledMethod
  end

  def self.add_method(target, name, branches, static_scope, visibility = :public, file = :dynamic_add, line = 1, defn = false)
    cm = build_method(name, branches, file, line)

    unless static_scope
      static_scope = Rubinius::StaticScope.new(
        self,
        Rubinius::StaticScope.new(Object)
      )
    end

    cm.scope = static_scope

    if defn and not Thread.current[:atomy_check_scope]
      Rubinius.add_defn_method name, cm, static_scope, visibility
    else
      Rubinius.add_method name, cm, defn ? Object : target, visibility
    end
  end

  def self.define_method(target, name, receiver, body, arguments = [], static_scope = nil, visibility = :public, file = :dynamic_define, line = 1)
    method = [[receiver, arguments], body]
    methods = target.instance_variable_get(:"@atomy::#{name}")

    if methods
      insert_method(method, methods)
    else
      methods = target.instance_variable_set(:"@atomy::#{name}", [method])
    end

    add_method(target, name, methods, static_scope, visibility, file, line)
  end

  def self.compare(xs, ys, np, p)
    return 1 if xs.size > ys.size
    return -1 if xs.size < ys.size
    return 1 if np and not p
    return -1 if not np and p

    total = 0

    xs.zip(ys) do |x, y|
      total += x <=> y unless y.nil?
    end

    total <=> 0
  end

  def self.equivalent?(xs, ys)
    return false unless xs.size == ys.size

    xs.zip(ys) do |x, y|
      return false unless x =~ y
    end

    true
  end

  # this should mutate branches, so I don't have to call
  # instance_variable_set
  def self.insert_method(new, branches)
    if new[0][0].respond_to?(:<=>)
      if branches.instance_variable_get(:"@sorted")
        (nr, na), nb, np = new
        branches.each_with_index do |branch, i|
          (r, a), b, p = branch

          case compare([nr] + na, [r] + a, np, p)
          when 1
            return branches.insert(i, new)
          when 0
            if equivalent?([nr] + na, [r] + a)
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
          compare([a[0][0]] + a[0][1], [b[0][0]] + b[0][1], a[2], b[2])
        end

        branches.instance_variable_set(:"@sorted", true)

        branches
      end
    else
      branches.unshift(new)
    end
  end
end
