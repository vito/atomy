module Atomy::Patterns
  class Constant < Pattern
    attr_reader :constant, :value

    def initialize(constant, value = nil)
      @constant = constant
      @value = value
    end

    def construct(g)
      get(g)
      @constant.construct(g)
      @constant.compile(g)
      g.send :new, 2
    end

    def ==(b)
      b.kind_of?(Constant) and \
        @constant == b.constant
    end

    def target(g)
      if @value
        g.push_literal @value
      else
        @constant.bytecode(g)
      end
    end

    def matches?(g)
      target(g)
      g.swap
      g.kind_of
    end

    def assign(g, e, set = false)
      @constant.assign(g, e)
    end
  end
end
