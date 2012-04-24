module Atomy
  module AST
    class DefinePattern < Block
      include NodeLike
      extend SentientNode

      children :pattern, :body
      attributes :module_name
      generate

      def pattern_definer
        Atomy::AST::Define.new(
          0,
          @body,
          Atomy::AST::Block.new(
            0,
            [Atomy::AST::Primitive.new(0, :self)],
            []),
          [ Atomy::AST::Compose.new(
              0,
              Atomy::AST::Word.new(0, :node),
              Atomy::AST::Block.new(
                0,
                [@pattern],
                [])),
            @module_name
          ],
          :_pattern)
      end

      def bytecode(g, mod)
        pos(g)

        g.state.scope.nest_scope self

        blk = new_generator(g, :pattern_definition)
        blk.push_state self

        pos(blk)

        pattern_definer.bytecode(blk, mod)
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
