module Atomy
  module AST
    class Unquote < Node
      children :expression
      generate

      def construct(g, d = nil)
        pos(g)
        # TODO: fail if depth == 0
        if d == 1
          @expression.compile(g)
          g.send :to_node, 0
        elsif @expression.kind_of?(Splice) && d == 2
          @expression.get(g)
          g.push_int @line
          g.push_cpath_top
          g.find_const :Atomy
          @expression.expression.compile(g)
          g.send :unquote_splice, 1
          g.send :new, 2
        else
          get(g)
          g.push_int @line
          @expression.construct(g, unquote(d))
          g.send :new, 2
        end
      end

      def bytecode(g)
        pos(g)
        # TODO: this should raise an exception since
        # it'll only happen outside of a quasiquote.
        g.push_literal @expression
      end

      def unquote?
        true
      end

      def as_message(send)
        send
      end
    end
  end
end
