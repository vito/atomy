module Atomy::Patterns
  class BlockPass < Pattern
    attr_reader :pattern

    def initialize(p)
      @pattern = p
    end

    def construct(g)
      get(g)
      @pattern.construct(g)
      g.send :new, 1
    end

    def ==(b)
      b.kind_of?(BlockPass) and \
      @pattern == b.pattern
    end

    def target(g)
      g.push_const :Object
    end

    def matches?(g)
      g.pop
      g.push_true
    end

    def deconstruct(g, locals = {})
      nil_block = g.new_label
      done = g.new_label

      g.dup
      g.is_nil
      g.git nil_block

      g.push_cpath_top
      g.find_const :Proc
      g.swap
      g.send :__from_block__, 1
      @pattern.deconstruct(g, locals)
      g.goto done

      nil_block.set!
      g.pop

      done.set!
    end

    def local_names
      @pattern.local_names
    end
  end
end
