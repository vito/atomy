module Atomy
  module AST
    class Assign < Node
      children :left, :right
      generate

      def bytecode(g, mod)
        pos(g)
        mod.make_pattern(@left).assign(g, mod, @right)
      end
    end
  end
end
