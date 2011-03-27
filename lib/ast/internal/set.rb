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

        @rhs.bytecode(g)
        g.dup
        @lhs.to_pattern.match(g, true)
      end
    end
  end
end
