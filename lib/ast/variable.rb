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

      def bytecode(g)
        pos(g)

        var = g.state.scope.search_local(@name)
        if var
          var.get_bytecode(g)
        else
          g.push_self
          if @namespace
            g.call_custom((@namespace + "/" + @name).to_sym, 0)
          else
            g.call_custom @name.to_sym, 0
          end
        end
      end

      # used in macroexpansion
      def method_name
        name + ":@"
      end

      def namespace_symbol
        name.to_sym
      end
    end
  end
end
