module Atomy::Patterns
  class Quote < Pattern
    attributes(:expression)
    generate

    def construct(g)
      get(g)
      @expression.construct(g, nil)
      g.send :new, 1
    end

    def target(g)
      @expression.get(g)
    end

    def matches?(g)
      @expression.construct(g, nil)
      g.send :==, 1
    end
  end
end
