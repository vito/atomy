module Atomy
  module AST
    class Prefix < Node
      children :receiver
      attributes :operator

      def bytecode(g, mod)
        to_send.bytecode(g, mod)
      end

      def message_name
        :"#{@operator}@"
      end

      def macro_name
        :"_expand_:#{message_name}"
      end

      def to_send
        Send.new(
          :line => @line,
          :receiver => @receiver,
          :message_name => message_name)
      end
    end
  end
end
