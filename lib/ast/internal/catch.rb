module Atomy
  module AST
    class Catch < Node
      children :body, :rescue?, :else?
      generate

      def condition
        Rubinius::AST::RescueCondition.new(@line, nil, @rescue, nil)
      end

      # via Rubinius::AST::Rescue
      def bytecode(g)
        pos(g)

        g.push_modifiers
        if @body.nil?
          if @else.nil?
            # Stupid. No body and no else.
            g.push :nil
          else
            # Only an else, run it.
            @else.bytecode(g)
          end
        else
          outer_retry = g.retry

          this_retry = g.new_label
          reraise = g.new_label
          els     = g.new_label
          done    = g.new_label

          # Save the current exception into a stack local
          g.push_exception_state
          outer_exc_state = g.new_stack_local
          g.set_stack_local outer_exc_state
          g.pop

          this_retry.set!
          ex = g.new_label
          g.setup_unwind ex, Rubinius::AST::RescueType

          # TODO: ?
          g.new_label.set!

          if current_break = g.break
            # Make a break available to use, which we'll use to
            # lazily generate a cleanup area
            g.break = g.new_label
          end

          # Setup a lazy cleanup area for next'ing out of the handler
          current_next = g.next
          g.next = g.new_label

          # Use a lazy label to patch up prematuraly leaving a begin
          # body via retry.
          if outer_retry
            g.retry = g.new_label
          end

          # Also handle redo unwinding through the rescue
          if current_redo = g.redo
            g.redo = g.new_label
          end

          @body.bytecode(g)
          g.pop_unwind
          g.goto els

          if current_break
            if g.break.used?
              g.break.set!
              g.pop_unwind

              # Reset the outer exception
              g.push_stack_local outer_exc_state
              g.restore_exception_state

              g.goto current_break
            end

            g.break = current_break
          end

          if g.next.used?
            g.next.set!
            g.pop_unwind

            # Reset the outer exception
            g.push_stack_local outer_exc_state
            g.restore_exception_state

            if current_next
              g.goto current_next
            else
              g.ret
            end
          end

          g.next = current_next

          if current_redo
            if g.redo.used?
              g.redo.set!
              g.pop_unwind

              # Reset the outer exception
              g.push_stack_local outer_exc_state
              g.restore_exception_state

              g.goto current_redo
            end

            g.redo = current_redo
          end

          if outer_retry
            if g.retry.used?
              g.retry.set!
              g.pop_unwind

              # Reset the outer exception
              g.push_stack_local outer_exc_state
              g.restore_exception_state

              g.goto outer_retry
            end

            g.retry = outer_retry
          end

          # We jump here if an exception has occured in the body
          ex.set!

          # Expose the retry label here only, not before this.
          g.retry = this_retry

          # Save exception state to use in reraise
          g.push_exception_state

          raised_exc_state = g.new_stack_local
          g.set_stack_local raised_exc_state
          g.pop

          # Save the current exception, so that calling #=== can't trample
          # it.
          g.push_current_exception

          condition.bytecode(g, reraise, done, outer_exc_state)
          reraise.set!

          # Restore the exception state we saved and the reraise. The act
          # of checking if an exception matches can run any code, which
          # can easily trample on the current exception.
          #
          # Remove the direct exception so we can get to the state
          g.pop

          # Restore the state and reraise
          g.push_stack_local raised_exc_state
          g.restore_exception_state
          g.reraise

          els.set!
          if @else
            g.pop
            @else.bytecode(g)
          end

          done.set!

          g.push_stack_local outer_exc_state
          g.restore_exception_state
        end
        g.pop_modifiers
      end
    end
  end
end
