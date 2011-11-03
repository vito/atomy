module Atomy
  module AST
    class Word < Node
      attributes :text
      generate

      alias :message_name :text

      def bytecode(g)
        pos(g)

        var = g.state.scope.search_local(@text.to_sym)
        if var
          var.get_bytecode(g)
        else
          g.push_self
          g.allow_private
          g.send message_name.to_sym, 0
        end
      end

      def macro_name
        :"atomy_macro::@#{@text}"
      end

      def to_send
        Send.new(@line, Primitive.new(@line, :self), [], @text, nil, true)
      end
    end
  end
end
