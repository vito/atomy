module Atomy
  module AST
    class Splat < Node
      children :value
      generate

      def bytecode(g)
        pos(g)
        @value.compile(g)
        g.cast_array unless @value.kind_of?(List)
      end
    end
  end
end
