module Atomy
  module AST
    class Variable < Node
      attributes :name
      generate

      alias :message_name :name

      def bytecode(g)
        pos(g)

        var = g.state.scope.search_local(@name)
        if var
          var.get_bytecode(g)
        else
          g.push_self
          g.send message_name.to_sym, 0
        end
      end

      # TODO: this causes segfault when loading control-flow kernel
      # def macro_name
        # :"atomy_macro::@#{@name}"
      # end
    end
  end
end
