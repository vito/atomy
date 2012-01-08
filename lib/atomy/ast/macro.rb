module Atomy
  module AST
    class Macro < Node
      children :pattern, :body
      generate

      attr_writer :evaluated

      def bytecode(g)
        unless @evaluated
          Atomy::CodeLoader.module.define_macro(
            @pattern,
            @body,
            Atomy::CodeLoader.compiling)
        end

        pos(g)

        blk = new_generator(g, :macro_definition)
        blk.push_state Rubinius::AST::ClosedScope.new(@line)

        pos(blk)

        Atomy::CodeLoader.module.macro_definer(@pattern, @body).bytecode(blk)
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
