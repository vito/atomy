module Atomy
  module AST
    class MacroQuote < Node
      attributes :name, :contents, [:flags]
      generate

      def bytecode(g)
        pos(g)
        g.push_nil
      end

      def compile(g)
        Atomy::Macro::CURRENT_ENV.quote(
          @name,
          @contents,
          @flags
        ).compile(g)
      end
    end
  end
end
