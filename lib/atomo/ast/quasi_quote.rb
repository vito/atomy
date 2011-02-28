module Atomo
  module AST
    class QuasiQuote < Node
      attr_reader :expression

      def initialize(expression)
        @expression = expression
        @line = 1 # TODO
      end

      def ==(b)
        b.kind_of?(QuasiQuote) and \
        @expression == b.expression
      end

      def recursively(stop = nil, &f)
        return f.call self if stop and stop.call(self)

        f.call QuasiQuote.new(
          @expression.recursively(stop, &f)
        )
      end

      def construct(g, d)
        get(g)
        @expression.construct(g, d + 1)
        g.send :new, 1
      end

      def bytecode(g)
        pos(g)
        @expression.construct(g, 1)
      end
    end
  end
end