module Atomy::Patterns
  class Particle < Pattern
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
      b.kind_of?(Match) and \
      @value == b.value
    end

    def target(g)
      g.push_const :Symbol # TODO
    end

    def matches?(g)
      g.push_literal @value
      g.send :==, 1
    end
  end
end
