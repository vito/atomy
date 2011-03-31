module Atomy
  module AST
    class String < Node
      attributes :value
      generate

      def bytecode(g)
        pos(g)
        g.push_literal @value
        g.string_dup
      end
    end
  end
end
