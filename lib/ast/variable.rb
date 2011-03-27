module Atomy
  module AST
    class Variable < Node
      attributes :name
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
          g.send @name.to_sym, 0, true
        end
      end

      # used in macroexpansion
      def method_name
        name + ":@"
      end
    end
  end
end
