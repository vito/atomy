module Atomy
  module AST
    class Match < Node
      children :target, :body
      generate

      def bytecode(g)
        pos(g)

        done = g.new_label

        @target.compile(g)

        @body.contents.each do |e|
          MatchBranch.new(e.line, e.lhs, e.rhs).bytecode(g, done)
        end

        g.pop
        g.push_nil

        done.set!
      end
    end

    class MatchBranch < InlinedBody
      children :pattern, :branch
      generate

      def bytecode(g, done)
        pos(g)

        setup(g)

        skip = g.new_label

        pat = @pattern.to_pattern
        exp = @branch

        g.dup
        pat.matches?(g)
        g.gif skip

        pat.deconstruct(g)
        exp.compile(g)
        g.goto done

        skip.set!

        reset(g)
      end
    end
  end
end
