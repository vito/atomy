module Atomy
  module AST
    class DefinePattern < Block
      include NodeLike
      extend SentientNode

      children :pattern, :body
      attributes :module_name

      def pattern_definer
        Atomy::AST::DefineMethod.new(
          :line => 0,
          :body => @body,
          :receiver => Atomy::AST::Block.new(
            :line => 0,
            :contents => [Atomy::AST::Primitive.new(:line => 0, :value => :self)]),
          :arguments => [
            Atomy::AST::Compose.new(
              :line => 0,
              :left => Atomy::AST::Word.new(:line => 0, :text => :node),
              :right => Atomy::AST::Block.new(
                :line => 0,
                :contents => [@pattern])),
            @module_name
          ],
          :name => :_pattern,
          :always_match => true)
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
