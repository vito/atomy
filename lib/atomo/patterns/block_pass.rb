module Atomo::Patterns
  class BlockPass < Pattern
    attr_accessor :name

    def initialize(p)
      @pattern = p
    end

    def target(g)
      g.push_const :Object
    end

    def matches?(g)
      g.pop
      g.push_true
    end

    def deconstruct(g, locals = {})
      @pattern.deconstruct(g, locals)
    end

    def local_names
      @pattern.local_names
    end
  end
end
