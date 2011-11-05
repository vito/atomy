module Atomy
  module AST
    class ClassVariable < Node
      attributes :identifier
      generate

      def name
        ("@@" + @identifier).to_sym
      end

      def bytecode(g)
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
