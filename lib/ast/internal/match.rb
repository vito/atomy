module Atomo
  module AST
    class Match < Node
      children :target, :body
      generate

      def bytecode(g)
        pos(g)

        done = g.new_label

        @target.bytecode(g)

        @body.contents.each do |e|
          skip = g.new_label

          pat = e.lhs.to_pattern
          exp = e.rhs

          g.dup
          pat.matches?(g)
          g.gif skip

          pat.deconstruct(g)
          exp.bytecode(g)
          g.goto done

          skip.set!
        end

        g.pop
        g.push_nil

        done.set!
      end
    end
  end
end
