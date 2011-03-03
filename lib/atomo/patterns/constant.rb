module Atomo::Patterns
  class Constant < Pattern
    attr_reader :name

    def initialize(constant)
      @constant = constant
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
