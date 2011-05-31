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

      def prepare_all
        dup.tap do |x|
          x.rhs = x.rhs.prepare_all
        end
      end
    end
  end
end
