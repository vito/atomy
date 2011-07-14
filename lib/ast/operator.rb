module Atomy
  module AST
    class Operator < Node
      attributes [:operators], [:associativity, ":left"], [:precedence, 5]
      generate

      def bytecode(g)
        pos(g)
        g.push_cpath_top
        g.find_const :Atomy
        @operators.each do |o|
          g.push_literal o
        end
        g.make_array @operators.size
        g.push_literal @associativity
        g.push_int @precedence
        g.send :set_op_info, 3
      end
    end
  end
end
