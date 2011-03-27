module Atomo
  module AST
    class MacroQuote < Node
      attributes :name, :contents, [:flags]
      generate

      def bytecode(g)
        pos(g)
        g.push_nil
      end
    end
  end
end
