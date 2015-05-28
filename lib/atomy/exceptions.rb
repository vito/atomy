module Atomy
  class MethodFail < ArgumentError
    attr_reader :method_name, :arguments

    def initialize(mn, a)
      @method_name = mn
      @arguments = a
    end

    def message
      "method '#{@method_name}' did not understand " +
        "the given arguments: #{@arguments.inspect}"
    end
  end

  class PatternMismatch < RuntimeError
    def initialize(t, v)
      @type = t
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
