module Atomo
  module AST
    class Set < Node
      def initialize(line, lhs, rhs)
        @lhs = lhs
        @rhs = rhs
        @line = line
      end

      def recursively(stop = nil, &f)
        return f.call self if stop and stop.call(self)

        f.call Set.new(
          @line,
          @lhs.recursively(stop, &f),
          @rhs.recursively(stop, &f)
        )
      end

      def bytecode(g)
        pos(g)

        pat = Patterns.from_node(@lhs)
        @rhs.bytecode(g)
        g.dup
        pat.match(g, true)
      end
    end
  end
end
