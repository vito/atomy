module Atomy
  module AST
    class While < Node
      children :condition, :body
      attributes [:check_first, true]
      generate

      def condition_bytecode(g, bottom, use_gif)
        @condition.compile(g)
        if use_gif
          g.gif bottom
        else
          g.git bottom
        end
      end

      def body_bytecode(g, lbl)
        g.state.push_loop
        @body.compile(g)
        g.state.pop_loop

        # This is a loop epilogue. Nothing that changes
        # computation should be put here.
        lbl.set!
        g.pop
        g.check_interrupts
      end

      def bytecode(g, use_gif = true)
        pos(g)

        g.push_modifiers

        top = g.new_label
        post = g.next = g.new_label
        bottom = g.new_label

        g.break = g.new_label

        if @check_first
          g.redo = g.new_label

          top.set!
          condition_bytecode(g, bottom, use_gif)

          g.redo.set!
          body_bytecode(g, post)
        else
          g.redo = top

          top.set!
          body_bytecode(g, post)

          condition_bytecode(g, bottom, use_gif)
        end

        g.goto top

        bottom.set!
        g.push :nil
        g.break.set!

        g.pop_modifiers
      end
    end

    class Until < While
      def bytecode(g)
        super(g, false)
      end
    end
  end
end
