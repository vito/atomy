module Atomy
  class MethodFail < ArgumentError
    attr_reader :method_name

    def initialize(mn)
      @method_name = mn
    end

    def message
      "method #{@method_name} did not understand " +
        "its arguments (non-exhaustive patterns)"
    end
  end

  class PatternMismatch < RuntimeError
    def initialize(p, v)
      @pattern = p
      @value = v
    end
  end

  class UnquoteDepth < RuntimeError
    def initialize(e)
      @expression = e
    end

    def message
      "unquoted outside of a quasiquotation"
    end
  end
end
