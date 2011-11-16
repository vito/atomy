module Atomy
  module AST
    class Binary < Node
      Operators = {
        :+    => :meta_send_op_plus,
        :-    => :meta_send_op_minus,
        :==   => :meta_send_op_equal,
        :===  => :meta_send_op_tequal,
        :<    => :meta_send_op_lt,
        :>    => :meta_send_op_gt
      }

      children :lhs, :rhs
      attributes :operator
      slots [:private, "false"]
      generate

      alias :message_name :operator

      def bytecode(g)
        pos(g)
        @lhs.compile(g)
        @rhs.compile(g)

        if meta = Operators[@operator.to_sym]
          g.__send__ meta, g.find_literal(@operator.to_sym)
        else
          g.send @operator.to_sym, 1
        end
      end

      def macro_name
        :"atomy_macro::#{@operator}"
      end
    end
  end
end
