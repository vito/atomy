module Atomy
  module AST
    class IfThenElse < Node
      children :condition, :then, :else
      generate

      def bytecode(g)
        done = g.new_label
        nope = g.new_label

        @condition.compile(g)
        g.gif nope

        @then.compile(g)
        g.goto done

        nope.set!
        @else.compile(g)

        done.set!
      end
    end
  end
end
