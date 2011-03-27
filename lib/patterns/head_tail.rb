module Atomy::Patterns
  class HeadTail < Pattern
    attr_reader :head, :tail

    def initialize(head, tail)
      @head = head
      @tail = tail
    end

    def construct(g)
      get(g)
      @head.construct(g)
      @tail.construct(g)
      g.send :new, 2
    end

    def ==(b)
      b.kind_of?(HeadTail) and \
      @head == b.head and \
      @tail == b.tail
    end

    def target(g)
      g.push_const :Array
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

    def local_names
      @head.local_names + @tail.local_names
    end

    def bindings
      @head.bindings + @tail.bindings
    end
  end
end
