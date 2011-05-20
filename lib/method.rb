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

  def self.match_self?(pat)
    case pat
    when Patterns::Match
      pat.value != :self
    when Patterns::Constant
      false
    when Patterns::Named
      match_self?(pat.pattern)
    else
      true
    end
  end

  def self.build_method(name, branches, is_macro = false, file = :dynamic, line = 1)
    g = Rubinius::Generator.new
    g.name = name.to_sym
    g.file = file.to_sym
    g.set_line Integer(line)

    done = g.new_label
    mismatch = g.new_label

    g.push_state Rubinius::AST::ClosedScope.new(line)

    g.state.push_name name

    block_offset = is_macro ? 1 : 0

    total = 0
    min_reqs = nil
    reqs = 0
    defs = 0
    names = []
    splatted = false

    resolved = branches.collect do |pats, meth|
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

      [pats[0], segs, meth]
    end

    names.uniq!

    if splatted
      g.splat_index = block_offset + reqs + defs
    end

    total += block_offset

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
    resolved.each do |recv, (reqs, defs, splat, block), meth|
      skip = g.new_label
      argmis = g.new_label

      if reqs.size > min_reqs
        g.passed_arg((reqs.size + block_offset) - 1)
        g.gif skip
      end

      if match_self?(recv)
        g.dup
        recv.matches?(g)
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
        if is_macro
          g.push_local(0)
          block.pattern.deconstruct(g, locals)
        else
          g.push_block_arg
          block.deconstruct(g, locals)
        end
      end

      reqs.each_with_index do |a, i|
        g.push_local(i + block_offset)

        if a.bindings > 0
          g.dup
          a.matches?(g)
          g.gif argmis
          a.deconstruct(g, locals)
        else
          a.matches?(g)
          g.gif skip
        end
      end

      defs.each_with_index do |d, i|
        passed = g.new_label
        decons = g.new_label

        num = reqs.size + i + block_offset
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

    g.invoke_primitive :vm_check_super_callable, 0
    g.gif mismatch

    g.push_block
    if g.state.super?
      g.zsuper g.state.super.name
    else
      g.zsuper nil
    end
    g.goto done

    mismatch.set!
    g.push_self
    g.push_cpath_top
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

  def self.add_method(target, name, branches, static_scope, visibility = :public, is_macro = false)
    cm = build_method(name, branches, is_macro)

    unless static_scope
      static_scope = Rubinius::StaticScope.new(
        self,
        Rubinius::StaticScope.new(Object)
      )
    end

    cm.scope = static_scope

    Rubinius.add_method name, cm, target, visibility
  end

  def self.compare_heads(xs, ys)
    return 1 if xs.size > ys.size
    return -1 if xs.size < ys.size

    xs.zip(ys) do |x, y|
      cmp = x <=> y
      return cmp unless cmp == 0
    end

    0
  end

  def self.equivalent?(xs, ys)
    return false unless xs.size == ys.size

    xs.zip(ys) do |x, y|
      return false unless x =~ y
    end

    true
  end

  def self.insert_method(new, branches)
    (nr, na), nb = new
    if nr.respond_to?(:<=>)
      branches.each_with_index do |branch, i|
        (r, a), b = branch
        case compare_heads([nr] + na, [r] + a)
        when 1
          return branches.insert(i, new)
        when 0
          if equivalent?([nr] + na, [r] + a)
            branches[i] = new
            return branches
          end
        end
      end
    end

    branches << new
  end
end
