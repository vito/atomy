module Atomo
  module AST
    class Unquote < Node
      Atomo::Parser.register self

      def self.rule_name
        "unquote"
      end

      def initialize(expression)
        @expression = expression
        @line = 1 # TODO
      end

      attr_reader :expression

      def recursively(stop = nil, &f)
        return f.call self if stop and stop.call(self)

        f.call Unquote.new(
          @expression.recursively(stop, &f)
        )
      end

      def construct(g, d)
        if d == 0
          @expression.bytecode(g)
          g.send :to_node, 0
        else
          get(g)
          @expression.construct(g, d - 1)
          g.send :new, 1
        end
      end

      def self.grammar(g)
        g.unquote =
          g.seq("~", g.t(:level1)) do |e|
            Unquote.new(e)
          end
      end

      def bytecode(g)
        pos(g)
        # TODO: this should raise an exception since
        # it'll only happen outside of a quasiquote.
        g.push_literal @expression
      end
    end
  end
end