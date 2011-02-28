module Atomo
  module AST
    class IfThenElse < Rubinius::AST::Class
      include NodeLike

      def initialize(line, cond, thenb, elseb)
        @line = line
        @condition = cond
        @then = thenb
        @else = elseb
      end

      def recursively(stop = nil, &f)
        return f.call self if stop and stop.call(self)

        IfThenElse.new(
          @line,
          @condition.recursively(stop, &f),
          @then.recursively(stop, &f),
          @else.recursively(stop, &f)
        )
      end

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