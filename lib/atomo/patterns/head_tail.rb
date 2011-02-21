module Atomo::Patterns
  class HeadTail < Pattern
    def initialize(head, tail)
      @head = head
      @tail = tail
    end

    def target(g)
      g.push_const :Array
    end

    def matches?(g)
      mismatch = g.new_label
      matched = g.new_label

      g.dup
      g.dup
      g.send :empty?, 0
      g.gif mismatch

      g.shift_array
      @head.matches?(g)
      g.gif mismatch

      @tail.matches?(g)
      g.goto matched

      mismatch.set!
      g.push_false

      matched.set!
    end

    def match(g)
      matched = g.new_label
      mismatch = g.new_label

      g.dup # dup once for size, another for shifting
      g.dup
      g.send :empty?, 0
      g.git mismatch

      g.shift_array
      @head.match(g)
      @tail.match(g)

      g.goto matched

      mismatch.set!
      g.push_const :Exception
      g.push_literal "pattern mismatch"
      g.send :new, 1
      g.raise_exc

      matched.set!
    end

    def local_names
      @head.local_names + @tail.local_names
    end
  end
end