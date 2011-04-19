module Atomy
  module AST
    class MacroQuote < Node
      attributes :name, :contents, [:flags]
      generate

      def bytecode(g)
        pos(g)
        g.push_literal :impossible
      end

      def expand
        Atomy::Macro::Environment.quote(
          @name,
          @contents,
          @flags
        ).to_node
      end

      alias :prepare :expand
    end
  end
end
