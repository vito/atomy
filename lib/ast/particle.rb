module Atomy
  module AST
    class Particle < Node
      attributes :name
      generate

      def bytecode(g)
        pos(g)
        g.push_literal @name.to_sym
      end
    end
  end
end
