module Atomo
  module AST
    class Match < Node
      def initialize(target, body)
        @target = target
        @body = body
        @line = 1 # TODO
      end

      def recursively(&f)
        f.call Match.new(
          target.recursively(&f),
          body.recursively(&f)
        )
      end

      def bytecode(g)
        pos(g)

        done = g.new_label

        @target.bytecode(g)

        @body.body.expressions.each do |e|
          skip = g.new_label

          pat = Patterns.from_node(e.lhs)
          exp = e.rhs

          g.dup
          pat.matches?(g)
          g.gif skip

          g.dup
          pat.deconstruct(g)
          exp.bytecode(g)
          g.goto done

          skip.set!
        end

        g.push_nil

        done.set!
      end
    end
  end
end