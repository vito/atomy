module Atomy
  module AST
    class IfThenElse < Node
      children :condition, :then, :else
      generate

      def bytecode(g)
        done = g.new_label
        nope = g.new_label

        @condition.bytecode(g)
        g.gif nope

        @then.bytecode(g)
        g.goto done

        nope.set!
        @else.bytecode(g)

        done.set!
      end
    end
  end
end
