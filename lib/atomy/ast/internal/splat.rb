module Atomy
  module AST
    class Splat < Node
      children :value

      def bytecode(g, mod)
        pos(g)
        mod.compile(g, @value)
        g.cast_array unless @value.kind_of?(List)
      end
    end
  end
end
