module Atomy::Patterns
  class HeadTail < Pattern
    children(:head, :tail)
    generate

    def target(g)
      g.push_cpath_top
      g.find_const :Array
    end

    def matches?(g)
      mismatch = g.new_label
      matched = g.new_label

      g.dup
      g.send :empty?, 0
      g.git mismatch

      g.shift_array

      @head.matches?(g)
      g.gif mismatch

      @tail.matches?(g)
      g.goto matched

      mismatch.set!
      g.pop
      g.push_false

      matched.set!
    end

    def deconstruct(g, locals = {})
      g.shift_array
      @head.deconstruct(g, locals)
      @tail.deconstruct(g, locals)
    end
  end
end
