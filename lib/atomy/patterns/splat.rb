module Atomy::Patterns
  class Splat < Pattern
    attr_accessor :pattern

    def initialize(p)
      @pattern = p
    end

    def construct(g)
      get(g)
      @pattern.construct(g)
      g.send :new, 1
    end

    def ==(b)
      b.kind_of?(Splat) and \
      @pattern == b.pattern
    end

    def target(g)
      g.push_const :Object
    end

    def matches?(g)
      @pattern.matches?(g)
    end

    def deconstruct(g, locals = {})
      g.cast_array
      g.send :to_list, 0
      @pattern.deconstruct(g, locals)
    end

    def local_names
      @pattern.local_names
    end

    def bindings
      @pattern.bindings
    end
  end
end
