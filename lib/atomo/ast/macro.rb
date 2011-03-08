module Atomo
  module AST
    class Macro < Node
      attr_reader :pattern, :body

      def initialize(line, pattern, body)
        @pattern = pattern
        @body = body
        @line = line
      end

      def construct(g, d)
        get(g)
        g.push_int @line
        @pattern.construct(g)
        @body.construct(g, d)
        g.send :new, 3
      end

      def ==(b)
        b.kind_of?(Macro) and \
        @pattern == b.pattern and \
        @body == b.body
      end

      # TODO: if #recursively? is defined, see stages.rb;
      # not sure if Pragmas should look through their bodies.

      def bytecode(g)
        pos(g)
        @pattern.construct(g, nil)
        @body.construct(g, nil)
        g.send :register_macro, 1
      end
    end
  end
end
