module Atomy
  module AST
    class Unary < Node
      children :receiver
      attributes :operator
      generate

      def bytecode(g)
        pos(g)
        @receiver.compile(g)
        g.send message_name, 0
      end

      def message_name
        :"#{@operator}@"
      end

      def macro_name
        :"atomy_macro::#{@operator}@"
      end
    end
  end
end
