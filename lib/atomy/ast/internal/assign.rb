module Atomy
  module AST
    class Assign < Node
      children :lhs, :rhs
      generate

      def bytecode(g, mod)
        pos(g)
        mod.make_pattern(@lhs).assign(g, mod, @rhs)
      end
    end
  end
end
