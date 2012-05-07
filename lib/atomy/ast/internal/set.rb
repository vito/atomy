module Atomy
  module AST
    class Set < Node
      children :left, :right

      def bytecode(g, mod)
        pos(g)
        mod.make_pattern(@left).assign(g, mod, @right, true)
      end
    end
  end
end
