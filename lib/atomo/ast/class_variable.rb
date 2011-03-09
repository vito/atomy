module Atomo
  module AST
    class ClassVariable < Node
      attributes :name
      generate

      def bytecode(g)
        pos(g)
        if g.state.scope.module?
          g.push :self
        else
          g.push_scope
        end
        g.push_literal(("@@" + @name).to_sym)
        g.send :class_variable_get, 1
      end
    end
  end
end