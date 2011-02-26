module Atomo::Patterns
  class Quote < Pattern
    def initialize(x)
      @expression = x
    end

    def target(g)
      Constant.new(@expression.class.name.split("::")).target(g)
    end

    def matches?(g)
      g.push_literal @expression
      g.send :==, 1
    end
  end
end