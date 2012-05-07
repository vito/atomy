module Atomy
  module AST
    class Unquote < Node
      children :expression

      def construct(g, mod, d = nil)
        pos(g)

        # unquoting at depth 1; compile
        if d == 1
          if splice?
            mod.compile(g, @expression.receiver)
            g.push_cpath_top
            g.find_const :Proc
            g.push_literal :to_node
            g.send :__from_block__, 1
            g.send_with_block :collect, 0, false
          else
            mod.compile(g, @expression)
            g.send :to_node, 0
          end

        # patch up ``[~~*xs]
        # e.g. xs = ['1, '2, 3], ``[~~*xs] => `[~*['1, '2, '3]]
        elsif @expression.splice? && d == 2
          @expression.get(g)
          g.push_int @line
          g.push_cpath_top
          g.find_const :Atomy
          mod.compile(g, @expression.expression)
          g.send :unquote_splice, 1
          g.send :new, 2

        # unquoted too far
        elsif d && d < 1
          too_far(g)

        # not unquoting anything; construct
        else
          get(g)
          g.push_int @line
          @expression.construct(g, mod, unquote(d))
          g.send :new, 2
        end
      end

      def bytecode(g, mod)
        pos(g)
        too_far(g, mod)
      end

      def too_far(g, mod)
        g.push_self
        g.push_literal @expression
        g.push_cpath_top
        g.find_const :Atomy
        g.find_const :UnquoteDepth
        @expression.construct(g, mod)
        g.send :new, 1
        g.allow_private
        g.send :raise, 1
      end

      def unquote?
        true
      end

      def splice?
        case @expression
        when Prefix
          @expression.operator == :*
        when Pattern
          @expression.pattern.is_a?(Atomy::Patterns::Splat)
        else
          false
        end
      end
    end
  end
end
