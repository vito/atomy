module Atomo
  module AST
    class QuasiQuote < Node
      Atomo::Parser.register self

      def self.rule_name
        "quasi_quote"
      end

      def initialize(expression)
        @expression = expression
        @line = 1 # TODO
      end

      attr_reader :expression

      def recursively(stop = nil, &f)
        return f.call self if stop and stop.call(self)

        f.call QuasiQuote.new(
          @expression.recursively(stop, &f)
        )
      end

      def construct(g, d)
        get(g)
        @expression.construct(g, d + 1)
        g.send :new, 1
      end

      def self.grammar(g)
        g.quasi_quote =
          g.seq("`", g.t(:level1)) do |e|
            QuasiQuote.new(e)
          end
      end

      def bytecode(g)
        pos(g)
        @expression.construct(g, 0)
      end
    end
  end
end