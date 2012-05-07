module Atomy
  module AST
    class QuasiQuote < Node
      children :expression

      def construct(g, mod, d = nil)
        get(g)
        g.push_int @line
        @expression.construct(g, mod, quote(d))
        g.send :new, 2
      end

      def bytecode(g, mod)
        pos(g)
        @expression.construct(g, mod, 1)
      end
    end
  end
end
