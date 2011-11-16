module Atomy
  module AST
    class Set < Node
      children :lhs, :rhs
      generate

      def bytecode(g)
        pos(g)
        @lhs.pattern.assign(g, @rhs, true)
      end
    end
  end
end
