module Atomy
  module AST
    class Assign < Node
      children :lhs, :rhs
      generate

      def bytecode(g, mod)
        pos(g)
        @lhs.pattern.assign(g, mod, @rhs)
      end
    end
  end
end
