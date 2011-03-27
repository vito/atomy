module Atomo
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
        g.send :call, 0
        g.goto done

        nope.set!
        @else.bytecode(g)
        g.send :call, 0

        done.set!
      end
    end
  end
end
