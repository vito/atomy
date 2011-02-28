module Atomo::Patterns
  class Quote < Pattern
    def initialize(x)
      @expression = x
    end

    def ==(b)
      b.kind_of?(Quote) and \
      @expression == b.expression
    end

    def target(g)
      Constant.new(-1, @expression.class.name.split("::")).target(g)
    end

    def matches?(g)
      g.push_literal @expression
      g.send :==, 1
    end
  end
end