module Atomy
  module AST
    class Macro < Block
      include NodeLike
      extend SentientNode

      children :pattern, :body
      generate

      attr_writer :evaluated

      def bytecode(g, mod)
        pos(g)

        g.state.scope.nest_scope self

        blk = new_generator(g, :macro_definition)
        blk.push_state self

        pos(blk)

        mod.macro_definer(@pattern, @body).bytecode(blk, mod)
        blk.ret

        blk.close
        blk.pop_state

        g.create_block blk
        g.push_self
        g.push_rubinius
        g.find_const :StaticScope
        g.push_cpath_top
        g.find_const :Atomy
        g.find_const :AST
        g.push_rubinius
        g.find_const :StaticScope
        g.push_self
        g.send :new, 1
        g.send :new, 2
        g.send :call_under, 2
      end
    end
  end
end
