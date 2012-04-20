module Atomy
  module AST
    class Binary < Node
      children :lhs, :rhs
      attributes :operator, [:private, "false"]
      generate

      alias :message_name :operator

      def bytecode(g, mod)
        to_send.bytecode(g, mod)
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
