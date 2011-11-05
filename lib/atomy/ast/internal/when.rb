module Atomy
  module AST
    class When < Node
      children :condition, :then
      generate

      def bytecode(g)
        done = g.new_label
        nope = g.new_label

        @condition.compile(g)
        g.gif nope

        @then.compile(g)
        g.goto done

        nope.set!
        g.push_nil

        done.set!
      end
    end
  end
end
