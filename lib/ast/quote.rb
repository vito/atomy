module Atomy
  module AST
    class Quote < Node
      children :expression
      generate

      def bytecode(g)
        pos(g)
        @expression.recursively(&:resolve).construct(g)
      end
    end
  end
end
