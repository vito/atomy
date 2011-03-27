module Atomy
  module AST
    class BinarySend < Node
      children :lhs, :rhs
      attributes :operator, [:private, "false"]
      generate

      alias :method_name :operator

      def register_macro(body)
        Atomy::Macro.register(
          @operator,
          [@lhs, @rhs].collect do |n|
            Atomy::Macro.macro_pattern n
          end,
          body
        )
      end

      def bytecode(g)
        pos(g)
        @lhs.bytecode(g)
        @rhs.bytecode(g)
        g.send @operator.to_sym, 1, @private
      end
    end
  end
end
