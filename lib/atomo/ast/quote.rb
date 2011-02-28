module Atomo
  module AST
    class Quote < Node
      attr_reader :expression

      def initialize(line, expression)
        @expression = expression
        @line = line
      end

      def ==(b)
        b.kind_of?(Quote) and \
        @expression == b.expression
      end

      def recursively(stop = nil, &f)
        return f.call self if stop and stop.call(self)

        f.call Quote.new(
          @line,
          @expression.recursively(stop, &f)
        )
      end

      def construct(g, d)
        get(g)
        g.push_int @line
        @expression.construct(g, d)
        g.send :new, 2
      end

      def bytecode(g)
        pos(g)
        g.push_literal @expression
      end
    end
  end
end
