module Atomy::Patterns
  class Literal < Pattern
    attr_reader :value

    def initialize(x)
      @value = x
    end

    def construct(g)
      get(g)
      g.push_literal @value
      g.send :new, 1
    end

    def ==(b)
      b.kind_of?(Literal) and \
      @value == b.value
    end

    def target(g)
      Atomy.const_from_string(g, @value.class.name)
    end

    def matches?(g)
      g.push_literal @value
      g.send :==, 1
    end
  end
end
