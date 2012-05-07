module Atomy
  module AST
    class IfThenElse < Node
      children :condition, :then, :else

      def bytecode(g, mod)
        done = g.new_label
        nope = g.new_label

        mod.compile(g, @condition)
        g.gif nope

        mod.compile(g, @then)
        g.goto done

        nope.set!
        mod.compile(g, @else)

        done.set!
      end
    end
  end
end
