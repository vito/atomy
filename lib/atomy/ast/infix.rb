module Atomy
  module AST
    class Infix < Node
      children :left, :right
      attributes :operator, [:private, false]

      alias :message_name :operator

      def bytecode(g, mod)
        to_send.bytecode(g, mod)
      end

      def to_send
        Send.new(
          @line,
          @left,
          [@right],
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
