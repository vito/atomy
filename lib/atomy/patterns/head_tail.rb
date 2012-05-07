module Atomy::Patterns
  class HeadTail < Pattern
    children(:head, :tail)

    def target(g, mod)
      g.push_cpath_top
      g.find_const :Array
    end

    def matches?(g, mod)
      mismatch = g.new_label
      matched = g.new_label

      g.dup
      g.push_cpath_top
      g.find_const :Array
      g.swap
      g.kind_of
      g.gif mismatch

      g.dup
      g.send :empty?, 0
      g.git mismatch

      g.shift_array

      @head.matches?(g, mod)
      g.gif mismatch

      @tail.matches?(g, mod)
      g.goto matched

      mismatch.set!
      g.pop
      g.push_false

      matched.set!
    end

    def deconstruct(g, mod, locals = {})
      g.shift_array
      @head.deconstruct(g, mod, locals)
      @tail.deconstruct(g, mod, locals)
    end
  end
end
