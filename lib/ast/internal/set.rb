module Atomy
  module AST
    class Set < Node
      children :lhs, :rhs
      generate

      def bytecode(g)
        pos(g)
        @lhs.pattern.assign(g, @rhs, true)
      end

      def prepare_all
        dup.tap do |x|
          x.rhs = x.rhs.prepare_all
        end
      end
    end
  end
end
