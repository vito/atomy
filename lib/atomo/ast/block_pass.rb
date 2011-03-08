module Atomo
  module AST
    class BlockPass < Rubinius::AST::BlockPass
      include NodeLike

      attr_reader :name

      def construct(g, d)
        get(g)
        g.push_int @line
        @body.construct(g, d)
        g.send :new, 2
      end

      def ==(b)
        b.kind_of?(BlockPass) and \
        @body == b.body
      end

      def recursively(stop = nil, &f)
        return f.call self if stop and stop.call(self)

        BlockPass.new(
          @line,
          @body.recursively(stop, &f)
        )
      end
    end
  end
end
