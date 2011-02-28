module Atomo
  module AST
    class Macro < Node
      attr_reader :pattern, :body

      def initialize(pattern, body)
        @pattern = pattern
        @body = body
        @line = 1 # TODO
      end

      def ==(b)
        b.kind_of?(Macro) and \
        @pattern == b.pattern and \
        @body == b.body
      end

      def construct(g, d)
        get(g)
        g.push_literal @pattern
        @body.construct(g, d)
        g.send :new, 2
      end

      # TODO: if #recursively? is defined, see stages.rb;
      # not sure if Pragmas should look through their bodies.

      def bytecode(g)
        pos(g)
        g.push_nil
      end
    end
  end
end
