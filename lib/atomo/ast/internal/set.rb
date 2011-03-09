module Atomo
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

        pat = Patterns.from_node(@lhs)
        @rhs.bytecode(g)
        g.dup
        pat.match(g, true)
      end
    end
  end
end
