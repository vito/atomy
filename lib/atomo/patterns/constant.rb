module Atomo::Patterns
  class Constant < Pattern
    attr_reader :constant

    def initialize(constant)
      @constant = constant
    end

    def construct(g)
      get(g)
      @constant.construct(g, nil)
      g.send :new, 1
    end

    def ==(b)
      b.kind_of?(Constant) and \
        @constant == b.constant
    end

    def target(g)
      @constant.bytecode(g)
    end

    def matches?(g)
      target(g)
      g.swap
      g.kind_of
    end
  end
end
