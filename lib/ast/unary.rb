# TODO: ensure binary sends do not end with @
module Atomy
  module AST
    class Unary < Node
      children :receiver
      attributes :operator
      slots :namespace?
      generate

      def register_macro(body)
        Atomy::Macro.register(
          @operator + "@",
          [Atomy::Macro.macro_pattern(@receiver)],
          body
        )
      end

      def message_name
        if @namespace && @namespace != "_"
          @namespace + "/" + @operator
        else
          @operator
        end
      end

      def compile(g)
        expand.bytecode(g)
      end

      def bytecode(g)
        pos(g)
        @receiver.compile(g)
        if @namespace == "_"
          g.send @operator.to_sym, 0
        else
          g.call_custom method_name.to_sym, 0
        end
      end

      def method_name
        @operator + "@"
      end
    end
  end
end
