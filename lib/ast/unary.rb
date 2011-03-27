# TODO: ensure binary sends do not end with @
module Atomy
  module AST
    class Unary < Node
      children :receiver
      attributes :operator
      generate

      def register_macro(body)
        Atomy::Macro.register(
          @operator + "@",
          [Atomy::Macro.macro_pattern(@receiver)],
          body
        )
      end

      def bytecode(g)
        pos(g)
        @receiver.bytecode(g)
        g.send(method_name.to_sym, 0)
      end

      def method_name
        @operator + "@"
      end
    end
  end
end
