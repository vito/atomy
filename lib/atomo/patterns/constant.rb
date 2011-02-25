module Atomo::Patterns
  class Constant < Pattern
    attr_reader :chain

    def initialize(chain)
      @chain = chain
    end

    def target(g)
      g.push_const @chain[0].to_sym
      @chain.drop(1).each do |n|
        g.find_const n.to_sym
      end
    end

    def matches?(g)
      target(g)
      g.swap
      g.kind_of
    end

    def construct(g)
      g.push_const :Atomo
      g.find_const :Patterns
      g.find_const :Constant
      g.push_literal @chain
      g.send :new, 1
    end
  end
end
