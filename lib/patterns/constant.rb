module Atomy::Patterns
  class Constant < Pattern
    attr_reader :constant, :ancestors

    def initialize(constant, ancestors = nil)
      @constant = constant
      @ancestors = ancestors
    end

    def construct(g)
      get(g)
      @constant.construct(g)
      @constant.bytecode(g)
      g.send :ancestors, 0
      g.send :new, 2
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
