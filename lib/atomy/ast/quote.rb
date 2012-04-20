module Atomy
  module AST
    class Quote < Node
      children :expression
      generate

      def bytecode(g, mod)
        pos(g)
        @expression.construct(g, mod)
      end
    end
  end
end
