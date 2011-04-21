# TODO: ensure binary sends do not end with @
module Atomy
  module AST
    class Unary < Node
      children :receiver
      attributes :operator
      slots :namespace?
      generate

      def register_macro(body, let = false)
        Atomy::Macro.register(
          @operator + "@",
          [Atomy::Macro.macro_pattern(@receiver)],
          body,
          let
        )
      end

      def message_name
        Atomy.namespaced(@namespace, @operator)
      end

      def prepare
        resolve.expand
      end

      def bytecode(g)
        pos(g)
        @receiver.compile(g)
        if @namespace == "_"
          g.send @operator.to_sym, 0
        else
          g.push_literal message_name.to_sym
          g.send :atomy_send, 1
          #g.call_custom method_name.to_sym, 0
        end
      end

      def method_name
        @operator + "@"
      end
    end
  end
end
