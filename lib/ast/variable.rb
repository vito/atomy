module Atomy
  module AST
    class Variable < Node
      attributes :name
      slots :namespace?
      generate

      def register_macro(body)
        Atomy::Macro.register(
          method_name,
          [],
          body
        )
      end

      def compile(g)
        expand.bytecode(g)
      end

      def message_name
        if @namespace && @namespace != "_"
          @namespace + "/" + @name
        else
          @name
        end
      end

      def bytecode(g)
        pos(g)

        var = g.state.scope.search_local(@name)
        if var
          var.get_bytecode(g)
        else
          g.push_self
          g.call_custom message_name.to_sym, 0
        end
      end

      # used in macroexpansion
      def method_name
        name + ":@"
      end

      def namespace_symbol
        name.to_sym
      end

      def as_message(send)
        send.dup.tap do |s|
          s.method_name = @name
        end
      end
    end
  end
end
