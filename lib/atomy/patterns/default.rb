module Atomy::Patterns
  class Default < Pattern
    children(:pattern)
    attributes(:default)
    generate

    def construct(g)
      get(g)
      @pattern.construct(g)
      @default.construct(g, nil)
      g.send :new, 2
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

    def wildcard?
      @pattern.wildcard?
    end
  end
end

