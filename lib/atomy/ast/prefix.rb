module Atomy
  module AST
    class Prefix < Node
      children :receiver
      attributes :operator
      generate

      def bytecode(g)
        to_send.bytecode(g)
      end

      def message_name
        :"#{@operator}@"
      end

      def macro_name
        :"atomy_macro::#{@operator}@"
      end

      def to_send
        Send.new(
          @line,
          @receiver,
          [],
          message_name)
      end
    end
  end
end
