module Atomy
  module AST
    class Postfix < Node
      children :receiver
      attributes :operator
      generate

      def bytecode(g)
        pos(g)
        @receiver.compile(g)
        g.send message_name, 0
      end

      def message_name
        :"#{@operator}@@"
      end

      def macro_name
        :"atomy_macro::#{@operator}@@"
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
