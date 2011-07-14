module Atomy
  module AST
    class Match < Node
      children :target, [:branches]
      generate

      def bytecode(g)
        pos(g)

        done = g.new_label

        @target.compile(g)

        @branches.each do |e|
          e.bytecode(g, done)
        end

        g.pop
        g.push_nil

        done.set!
      end
    end

    class MatchBranch < Node
      children :pattern, :branch
      generate

      def bytecode(g, done)
        HiddenMatchBranch.new(@line, @pattern, @branch).bytecode(g, done)
      end

      def prepare_all
        dup.tap do |x|
          x.branch = x.branch.prepare_all
        end
      end
    end

    class HiddenMatchBranch < InlinedBody
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
