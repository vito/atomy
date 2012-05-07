module Atomy
  module AST
    class ClassVariable < Node
      attributes :identifier

      def name
        :"@@#{@identifier}"
      end

      def bytecode(g, mod)
        pos(g)
        if g.state.scope.module?
          g.push :self
        else
          g.push_scope
        end
        g.push_literal name
        g.send :class_variable_get, 1
      end
    end
  end
end
