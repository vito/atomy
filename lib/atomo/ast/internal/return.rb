module Atomo
  module AST
    class Return < Node
      children :value
      generate

      def bytecode(g, force = false)
        if @value
          @value.bytecode(g)
        else
          g.push_nil
        end

        if lcl = g.state.rescue?
          g.push_stack_local lcl
          g.restore_esception_state
        end

        if g.state.block?
          g.raise_return
        elsif !force and g.state.ensure?
          g.ensure_return
        else
          g.ret
        end
      end
    end
  end
end
