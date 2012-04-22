module Atomy
  module AST
    class Set < Node
      children :lhs, :rhs
      generate

      def bytecode(g, mod)
        pos(g)
        mod.make_pattern(@lhs).assign(g, mod, @rhs, true)
      end
    end
  end
end
