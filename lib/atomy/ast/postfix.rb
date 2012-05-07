module Atomy
  module AST
    class Postfix < Node
      children :receiver
      attributes :operator

      def bytecode(g, mod)
        to_send.bytecode(g, mod)
      end

      def message_name
        :"#{@operator}@@"
      end

      def macro_name
        :"_expand_#{message_name}"
      end

      def to_send
        Send.new(
          @line,
          @receiver,
          [],
          message_name)
      end

      def to_word
        return unless @receiver.is_a?(Word)
        case @operator
        when :"!", :"?", :"="
          Word.new(@line, :"#{@receiver.text}#{@operator}")
        end
      end
    end
  end
end
