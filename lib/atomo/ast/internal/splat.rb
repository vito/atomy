module Atomo
  module AST
    class Splat < Rubinius::AST::SplatValue
      include NodeLike

      def construct(g, d = nil)
        get(g)
        g.push_int @line
        @value.construct(g, d)
        g.send :new, 2
      end

      def ==(b)
        b.kind_of?(Splat) and \
        @value == b.value
      end

      def bytecode(g)
        pos(g)
        super
      end
    end
  end
end
