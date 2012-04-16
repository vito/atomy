module Atomy
  module AST
    class Unquote < Node
      children :expression
      generate

      def construct(g, d = nil)
        pos(g)

        # unquoting at depth 1; compile
        if d == 1
          if splice?
            @expression.receiver.compile(g)
            g.push_cpath_top
            g.find_const :Proc
            g.push_literal :to_node
            g.send :__from_block__, 1
            g.send_with_block :collect, 0, false
          else
            @expression.compile(g)
            g.send :to_node, 0
          end

        # patch up ``[~~*xs]
        # e.g. xs = ['1, '2, 3], ``[~~*xs] => `[~*['1, '2, '3]]
        elsif @expression.splice? && d == 2
          @expression.get(g)
          g.push_int @line
          g.push_cpath_top
          g.find_const :Atomy
          @expression.expression.compile(g)
          g.send :unquote_splice, 1
          g.send :new, 2

        # unquoted too far
        elsif d && d < 1
          too_far(g)

        # not unquoting anything; construct
        else
          get(g)
          g.push_int @line
          @expression.construct(g, unquote(d))
          g.send :new, 2
        end
      end

      def bytecode(g)
        pos(g)
        too_far(g)
      end

      def too_far(g)
        g.push_self
        g.push_literal @expression
        g.push_cpath_top
        g.find_const :Atomy
        g.find_const :UnquoteDepth
        @expression.construct(g)
        g.send :new, 1
        g.allow_private
        g.send :raise, 1
      end

      def unquote?
        true
      end

      def splice?
        @expression.is_a?(Prefix) && @expression.operator == :*
      end
    end
  end
end
