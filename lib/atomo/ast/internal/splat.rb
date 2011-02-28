module Atomo
  module AST
    class Splat < Rubinius::AST::BlockPass
      include NodeLike

      def initialize(body)
        super(1, body) # TODO
      end

      def ==(b)
        b.kind_of?(Splat) and \
        @body == b.body
      end

      def bytecode(g)
        @body.bytecode(g)
        g.cast_array unless @body.kind_of? List
      end
    end
  end
end
