module Atomy
  module AST
    class Return < Node
      children :value

      def bytecode(g, mod)
        if @value
          mod.compile(g, @value)
        else
          g.push_nil
        end

        if lcl = g.state.rescue?
          g.push_stack_local lcl
          g.restore_exception_state
        end

        if g.state.ensure?
          g.ensure_return
        else
          g.ret
        end
      end
    end
  end
end
