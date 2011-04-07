module Atomy
  module AST
    class BinarySend < Node
      children :lhs, :rhs
      attributes :operator
      slots [:private, "false"], :namespace?
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

      def message_name
        if @namespace && !@namespace.empty?
          @namespace + "/" + @operator
        else
          @operator
        end
      end

      def compile(g)
        expand.bytecode(g)
      end

      def bytecode(g)
        pos(g)
        @lhs.compile(g)
        @rhs.compile(g)
        g.call_custom message_name.to_sym, 1
      end
    end
  end
end
