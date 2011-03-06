module Atomo
  module AST
    class Splat < Rubinius::AST::SplatValue
      include NodeLike

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
