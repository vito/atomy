module Atomy
  module AST
    class Primitive < Node
      attributes :value
      generate

      def bytecode(g)
        pos(g)

        # TODO: `(~#true) will break here
        case @value
        when :true, :false, :self, :nil, Integer
          g.push @value
        else
          g.push_literal @value
        end
      end
    end
  end
end
