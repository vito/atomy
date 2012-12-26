module Atomy
  module AST
    class Word < Node
      attributes :text

      alias :message_name :text

      def bytecode(g, mod)
        pos(g)

        var = g.state.scope.search_local(@text)
        if var
          var.get_bytecode(g)
        else
          to_send.bytecode(g, mod)
        end
      end

      def macro_name
        :"_expand_#{@text}"
      end

      def to_send
        Send.new(
          :line => @line,
          :receiver => Primitive.new(:line => @line, :value => :self),
          :message_name => @text,
          :private => true)
      end

      def to_word
        self
      end
    end
  end
end
