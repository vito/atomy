module Atomo
  module AST
    class Quote < Node
      children :expression
      generate

      def bytecode(g)
        pos(g)
        @expression.construct(g, nil)
      end
    end
  end
end
