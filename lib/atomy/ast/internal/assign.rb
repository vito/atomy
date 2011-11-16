module Atomy
  module AST
    class Assign < Node
      children :lhs, :rhs
      generate

      def bytecode(g)
        pos(g)
        @lhs.pattern.assign(g, @rhs)
      end
    end
  end
end
