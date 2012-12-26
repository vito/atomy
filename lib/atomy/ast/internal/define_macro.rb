module Atomy
  module AST
    class DefineMacro < Block
      include NodeLike
      extend SentientNode

      children :pattern, :body

      attr_writer :evaluated

      def macro_definer
        name = @pattern.macro_name

        DefineMethod.new(
          :line => @line,
          :body => Send.new(
            :line => @body.line,
            :receiver => @body,
            :message_name => :to_node),
          :receiver => Block.new(
            :line => @line,
            :contents => [Primitive.new(:line => @line, :value => :self)]),
          :arguments => [
            Compose.new(
              :left => Word.new(:text => :node),
              :right => Block.new(
                :contents => [
                  QuasiQuote.new(:line => @line, :expression => @pattern)
                ]))
          ],
          :name => name,
          :always_match => true)
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
        g.find_const :ConstantScope
        g.push_cpath_top
        g.find_const :Atomy
        g.find_const :AST
        g.push_rubinius
        g.find_const :ConstantScope
        g.push_self
        g.send :new, 1
        g.send :new, 2
        g.send :call_under, 2
      end
    end
  end
end
