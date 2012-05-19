module Atomy
  module AST
    class DefineMacro < Block
      include NodeLike
      extend SentientNode

      children :pattern, :body

      attr_writer :evaluated

      def macro_definer
        name = @pattern.macro_name

        Atomy::AST::DefineMethod.new(
          0,
          Atomy::AST::Send.new(
            @body.line,
            @body,
            [],
            :to_node),
          Atomy::AST::Block.new(
            0,
            [Atomy::AST::Primitive.new(0, :self)],
            []),
          [ Atomy::AST::Compose.new(
              0,
              Atomy::AST::Word.new(0, :node),
              Atomy::AST::Block.new(
                0,
                [Atomy::AST::QuasiQuote.new(0, @pattern)],
                []))
          ],
          name,
          nil,
          true)
      end

      def bytecode(g, mod)
        pos(g)

        g.state.scope.nest_scope self

        blk = new_generator(g, :macro_definition)
        blk.push_state self

        pos(blk)

        macro_definer.bytecode(blk, mod)
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
