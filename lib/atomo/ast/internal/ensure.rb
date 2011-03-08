module Atomo
  module AST
    class Ensure < Rubinius::AST::Ensure
      include NodeLike

      def construct(g, d = nil)
        get(g)
        g.push_int @line
        @body.construct(g, d)
        @ensure.construct(g, d)
        g.send :new, 3
      end

      def recursively(stop = nil, &f)
        return f.call self if stop and stop.call(self)

        Ensure.new(
          @line,
          @body.recursively(stop, &f),
          @ensure.recursively(stop, &f)
        )
      end
    end
  end
end
