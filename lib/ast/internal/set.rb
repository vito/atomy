module Atomy
  module AST
    class Set < Node
      children :lhs, :rhs
      generate

      def bytecode(g)
        pos(g)

        if @lhs.respond_to?(:assign)
          @lhs.assign(g, @rhs)
          return
        end

        @lhs.to_pattern.assign(g, @rhs, true)
      end
    end
  end
end
