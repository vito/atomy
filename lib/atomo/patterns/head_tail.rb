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

    def construct(g)
      g.push_const :Atomo
      g.find_const :Patterns
      g.find_const :Constant
      @head.construct(g)
      @tail.construct(g)
      g.send :new, 2
    end

    def local_names
      @head.local_names + @tail.local_names
    end
  end
end
