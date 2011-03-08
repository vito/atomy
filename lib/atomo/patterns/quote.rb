module Atomo::Patterns
  class Quote < Pattern
    def initialize(x)
      @expression = x
    end

    def construct(g)
      get(g)
      @expression.construct(g, nil)
      g.send :new, 1
    end

    def ==(b)
      b.kind_of?(Quote) and \
      @expression == b.expression
    end

    def target(g)
      # TODO
      Constant.new(-1, @expression.class.name.split("::")).target(g)
    end

    def matches?(g)
      @expression.construct(g, nil)
      g.send :==, 1
    end
  end
end
