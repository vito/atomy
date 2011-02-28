module Atomo
  module AST
    class Unquote < Node
      attr_reader :expression

      def initialize(expression)
        @expression = expression
        @line = 1 # TODO
      end

      def ==(b)
        b.kind_of?(Unquote) and \
        @expression == b.expression
      end

      def recursively(stop = nil, &f)
        return f.call self if stop and stop.call(self)

        f.call Unquote.new(
          @expression.recursively(stop, &f)
        )
      end

      def construct(g, d)
        # TODO: fail if depth == 0
        if d == 1
          @expression.bytecode(g)
          g.send :to_node, 0
        else
          get(g)
          @expression.construct(g, d - 1)
          g.send :new, 1
        end
      end

      def bytecode(g)
        pos(g)
        # TODO: this should raise an exception since
        # it'll only happen outside of a quasiquote.
        g.push_literal @expression
      end
    end
  end
end