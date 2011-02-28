module Atomo
  module AST
    class Splat < Rubinius::AST::BlockPass
      include NodeLike

      def ==(b)
        b.kind_of?(Splat) and \
        @body == b.body
      end

      def bytecode(g)
        pos(g)
        @body.bytecode(g)
        g.cast_array unless @body.kind_of? List
      end
    end
  end
end
