module Atomo
  module AST
    class Return < Rubinius::AST::Return
      include NodeLike

      def construct(g, d = nil)
        get(g)
        g.push_int @line
        @value.construct(g, d)
        g.send :new, 2
      end

      def recursively(stop = nil, &f)
        return f.call self if stop and stop.call(self)

        Return.new(
          @line,
          @value.recursively(stop, &f)
        )
      end
    end
  end
end
