module Atomy
  module AST
    class Quote < Node
      children :expression
      generate

      def bytecode(g)
        pos(g)
        @expression.construct(g)
      end

      def prepare_all
        self
      end
    end
  end
end
