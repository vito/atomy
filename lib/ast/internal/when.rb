module Atomy
  module AST
    class When < Node
      children :condition, :then
      generate

      def bytecode(g)
        done = g.new_label
        nope = g.new_label

        @condition.bytecode(g)
        g.gif nope

        @then.bytecode(g)
        g.goto done

        nope.set!
        g.push_nil

        done.set!
      end
    end
  end
end
