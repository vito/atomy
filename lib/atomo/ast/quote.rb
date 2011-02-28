module Atomo
  module AST
    class Quote < Node
      attr_reader :expression

      def initialize(expression)
        @expression = expression
        @line = 1 # TODO
      end

      def ==(b)
        b.kind_of?(Quote) and \
        @expression == b.expression
      end

      def recursively(stop = nil, &f)
        return f.call self if stop and stop.call(self)

        f.call Quote.new(
          @expression.recursively(stop, &f)
        )
      end

      def construct(g, d)
        get(g)
        @expression.construct(g, d)
        g.send :new, 1
      end

      def bytecode(g)
        pos(g)
        g.push_literal @expression
      end
    end
  end
end