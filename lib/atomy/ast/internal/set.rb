module Atomy
  module AST
    class Set < Node
      children :lhs, :rhs
      generate

      def bytecode(g, mod)
        pos(g)
        @lhs.pattern.assign(g, mod, @rhs, true)
      end
    end
  end
end
