module Atomy::Patterns
  class Default < Pattern
    attr_reader :pattern, :default

    def initialize(p, d)
      @pattern = p
      @default = d
    end

    def construct(g)
      get(g)
      @pattern.construct(g)
      @default.construct(g, nil)
      g.send :new, 2
    end

    def ==(b)
      b.kind_of?(Default) and \
      @pattern == b.pattern and \
      @default == b.default
    end

    def target(g)
      @pattern.target(g)
    end

    def matches?(g)
      @pattern.matches?(g)
    end

    def deconstruct(g, locals = {})
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

