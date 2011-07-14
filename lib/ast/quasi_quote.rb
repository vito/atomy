module Atomy
  module AST
    class QuasiQuote < Node
      children :expression
      generate

      def construct(g, d = nil)
        get(g)
        g.push_int @line
        @expression.construct(g, quote(d))
        g.send :new, 2
      end

      def bytecode(g)
        pos(g)
        @expression.construct(g, 1)
      end

      def prepare_all
        through_quotes(proc { true }, &:prepare_all)
      end
    end
  end
end
