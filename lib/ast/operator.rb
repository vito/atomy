module Atomy
  module AST
    class Operator < Node
      attributes [:operators], :associativity, :precedence
      generate

      def bytecode(g)
        pos(g)
        g.push_const :Atomy
        g.find_const :Macro
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
