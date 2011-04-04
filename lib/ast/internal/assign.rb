module Atomy
  module AST
    class Assign < Node
      children :lhs, :rhs
      generate

      def bytecode(g)
        pos(g)

        if @lhs.respond_to?(:assign)
          @lhs.assign(g, @rhs)
          return
        end

        @lhs.to_pattern.assign(g, @rhs)
      end
    end
  end
end
