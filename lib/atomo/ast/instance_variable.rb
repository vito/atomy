module Atomo
  module AST
    class InstanceVariable < Node
      attributes :name
      generate

      def bytecode(g)
        pos(g)
        g.push_ivar(("@" + @name).to_sym)
      end
    end
  end
end
