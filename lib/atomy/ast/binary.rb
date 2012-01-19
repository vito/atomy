module Atomy
  module AST
    class Binary < Node
      children :lhs, :rhs
      attributes :operator, [:private, "false"]
      generate

      alias :message_name :operator

      def bytecode(g)
        to_send.bytecode(g)
      end

      def to_send
        Send.new(
          @line,
          @lhs,
          [@rhs],
          @operator,
          nil,
          nil,
          @private)
      end

      def macro_name
        :"_expand_#{@operator}"
      end
    end
  end
end
