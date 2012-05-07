module Atomy
  module AST
    class Quote < Node
      children :expression

      def bytecode(g, mod)
        pos(g)
        @expression.construct(g, mod)
      end
    end
  end
end
