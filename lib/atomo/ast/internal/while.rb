module Atomo
  module AST
    class While < Rubinius::AST::While
      include NodeLike

      def initialize(line, cond, body, check_first = false)
        super
      end

      def construct(g, d = nil)
        get(g)
        g.push_int @line
        @condition.construct(g, d)
        @body.construct(g, d)
        g.push_literal @check_first
        g.send :new, 4
      end

      def recursively(stop = nil, &f)
        return f.call self if stop and stop.call(self)

        While.new(
          @line,
          @condition.recursively(stop, &f),
          @body.recursively(stop, &f),
          @check_first
        )
      end
    end
  end
end
