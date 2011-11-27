module Atomy::Patterns
  class List < Pattern
    children([:patterns])
    generate

    def target(g)
      g.push_cpath_top
      g.find_const :Array
    end

    def splat_info
      if @patterns.last.is_a?(Splat)
        return [true, @patterns.size - 1]
      else
        return [false, @patterns.size]
      end
    end

    def matches?(g)
      matched = g.new_label
      mismatch = g.new_label

      splat, required = splat_info

      g.dup
      g.push_literal :size
      g.send :respond_to?, 1
      g.gif mismatch

      g.dup
      g.push_literal :[]
      g.send :respond_to?, 1
      g.gif mismatch

      g.dup
      g.send :size, 0
      g.push_int required
      g.send(splat ? :== : :==, 1)
      g.gif mismatch

      @patterns.each_with_index do |p, i|
        g.dup
        if p.is_a?(Splat)
          g.push_int i
          g.send :drop, 1
        else
          g.push_int i
          g.send :[], 1
        end
        p.matches?(g)
        g.gif mismatch
      end
      g.pop

      g.push_true
      g.goto matched

      mismatch.set!
      g.pop
      g.push_false

      matched.set!
    end

    def deconstruct(g, locals = {})
      @patterns.each_with_index do |p, i|
        g.dup
        if p.is_a?(Splat)
          g.push_int i
          g.send :drop, 1
        else
          g.push_int i
          g.send :[], 1
        end
        p.deconstruct(g, locals)
      end
      g.pop
    end
  end
end
