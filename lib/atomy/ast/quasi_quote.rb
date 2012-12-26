module Atomy
  module AST
    class QuasiQuote < Node
      children :expression

      def construct(g, mod, d = nil)
        get(g)
        g.send :new, 0

        g.dup
        g.push_int @line
        g.send :line=, 1
        g.pop

        g.dup
        @expression.construct(g, mod, quote(d))
        g.send :expression=, 1
        g.pop
      end

      def bytecode(g, mod)
        pos(g)
        @expression.construct(g, mod, 1)
      end
    end
  end
end
