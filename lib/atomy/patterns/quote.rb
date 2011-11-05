module Atomy::Patterns
  class Quote < Pattern
    attr_reader :expression

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
      names = @expression.class.name.split("::")
      g.push_const names.slice!(0).to_sym
      names.each do |n|
        g.find_const n.to_sym
      end
    end

    def matches?(g)
      @expression.construct(g, nil)
      g.send :==, 1
    end
  end
end
