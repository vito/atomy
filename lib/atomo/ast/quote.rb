module Atomo
  module AST
    class Quote < Node
      Atomo::Parser.register self

      def self.rule_name
        "quote"
      end

      def initialize(expression)
        @expression = expression
        @line = 1 # TODO
      end

      attr_reader :expression

      def recursively(stop = nil, &f)
        return f.call self if stop and stop.call(self)

        f.call Quote.new(
          @expression.recursively(stop, &f)
        )
      end

      def construct(g, d)
        get(g)
        @expression.construct(g, d)
        g.send :new, 1
      end

      def self.grammar(g)
        g.quote =
          g.seq("'", g.t(:level1)) do |e|
            Quote.new(e)
          end
      end

      def bytecode(g)
        pos(g)
        g.push_literal @expression
      end
    end
  end
end