module Atomy
  module AST
    class BinarySend < Node
      children :lhs, :rhs
      attributes :operator
      slots [:private, "false"]
      generate

      alias :message_name :operator

      def bytecode(g)
        pos(g)
        @lhs.compile(g)
        @rhs.compile(g)
        g.send @operator.to_sym, 1
      end

      def macro_name
        :"atomy_macro::#{@operator}"
      end
    end
  end
end
