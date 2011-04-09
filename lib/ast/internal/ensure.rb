module Atomy
  module AST
    class Ensure < Node
      children :body, :ensure
      generate

      def bytecode(g)
        pos(g)

        ok = g.new_label
        ex = g.new_label
        g.setup_unwind ex, Rubinius::AST::EnsureType

        # TODO: ?
        g.new_label.set!

        g.push_exception_state
        outer_exc_state = g.new_stack_local
        g.set_stack_local outer_exc_state
        g.pop

        old_break = g.break
        new_break = g.new_label
        g.break = new_break

        old_next = g.next
        new_next = g.new_label
        g.next = new_next

        g.state.push_ensure
        @body.compile(g)
        g.state.pop_ensure

        g.break = old_break
        g.next = old_next

        g.pop_unwind
        g.goto ok

        check_break = nil

        if new_break.used?
          used_break_local = g.new_stack_local
          check_break = g.new_label

          new_break.set!
          g.pop_unwind

          g.push :true
          g.set_stack_local used_break_local
          g.pop

          g.goto check_break
        end

        check_next = nil

        if new_next.used?
          used_next_local = g.new_stack_local
          check_next = g.new_label

          new_next.set!
          g.pop_unwind

          g.push :true
          g.set_stack_local used_next_local
          g.pop

          g.goto check_next
        end

        ex.set!

        g.push_exception_state

        g.state.push_rescue(outer_exc_state)
        @ensure.compile(g)
        g.state.pop_rescue
        g.pop

        g.restore_exception_state

        # Re-raise the exception
        g.reraise

        ok.set!

        if check_break
          g.push :false
          g.set_stack_local used_break_local
          g.pop

          check_break.set!
        end

        if check_next
          g.push :false
          g.set_stack_local used_next_local
          g.pop

          check_next.set!
        end

        # Now, re-emit the code for the ensure which will run if there was no
        # exception generated.
        @ensure.compile(g)
        g.pop

        if check_break
          post = g.new_label

          g.push_stack_local used_break_local
          g.gif post

          if g.break
            g.goto g.break
          else
            g.raise_break
          end
          post.set!
        end

        if check_next
          post = g.new_label

          g.push_stack_local used_next_local
          g.gif post

          g.next ? g.goto(g.next) : g.ret
          post.set!
        end
      end
    end
  end
end
