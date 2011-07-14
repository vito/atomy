module Atomy
  module AST
    class BinarySend < Node
      children :lhs, :rhs
      attributes :operator
      slots [:private, "false"], :namespace?
      generate

      alias :message_name :operator

      def namespaced
        Atomy.namespaced(@namespace, @operator)
      end

      def bytecode(g)
        pos(g)
        @lhs.compile(g)
        g.push_literal namespaced.to_sym unless @namespace == "_"
        @rhs.compile(g)
        if @namespace == "_"
          g.send @operator.to_sym, 1
        else
          g.send :atomy_send, 2
          #g.call_custom message.to_sym, 1
        end
      end
    end
  end
end
