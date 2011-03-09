module Atomo
  module AST
    class Variable < Node
      attributes :name
      generate

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
    end
  end
end
