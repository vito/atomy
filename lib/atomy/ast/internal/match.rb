module Atomy
  module AST
    class Match < Node
      children :target, [:branches]

      def bytecode(g, mod)
        pos(g)

        done = g.new_label

        mod.compile(g, @target)

        @branches.each do |e|
          e.bytecode(g, mod, done)
        end

        g.pop
        g.push_nil

        done.set!
      end
    end

    class MatchBranch < Node
      children :pattern, :branch

      def bytecode(g, mod, done)
        pos(g)

        skip = g.new_label

        pat = mod.make_pattern(@pattern)
        exp = @branch

        g.dup
        pat.matches?(g, mod)
        g.gif skip

        pat.deconstruct(g, mod)
        mod.compile(g, exp)
        g.goto done

        skip.set!
      end
    end
  end
end
