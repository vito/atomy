module Atomo
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

        @rhs.bytecode(g)
        g.dup
        @lhs.to_pattern.match(g)
      end
    end
  end
end
