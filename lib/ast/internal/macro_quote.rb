module Atomy
  module AST
    class MacroQuote < Node
      attributes :name, :contents, [:flags], :value?
      generate

      def bytecode(g)
        pos(g)
        g.push_literal :impossible
      end

      def quote(n, c, fs = [], v = "")
        raise "unknown quoter #{n.inspect}"
      end

      def expand
        quote(
          @name.to_sym,
          @contents,
          @flags,
          @value
        ).to_node.expand
      end

      alias :prepare :expand
    end
  end
end
