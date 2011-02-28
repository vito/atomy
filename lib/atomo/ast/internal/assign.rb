module Atomo
  module AST
    class Assign < Node
      def initialize(line, lhs, rhs)
        @lhs = lhs
        @rhs = rhs
        @line = line
      end

      # TODO: recursively

      def bytecode(g)
        pos(g)

        if @lhs.kind_of? Constant
          if @lhs.chain.size == 1
            g.push_scope
          else
            @lhs.chain[0..-2].each_with_index do |n, i|
              if i == 0
                g.push_const n.to_sym
              else
                g.find_const n.to_sym
              end
            end
          end

          g.push_literal @lhs.chain.last.to_sym
          @rhs.bytecode(g)
          g.send :const_set, 2
          return
        end

        if @lhs.kind_of? UnarySend
          @lhs.receiver.bytecode(g)
          @rhs.bytecode(g)
          g.send((@lhs.method_name + "=").to_sym, 1)
          return
        end

        pat = Patterns.from_node(@lhs)
        @rhs.bytecode(g)
        g.dup
        pat.match(g)
      end
    end
  end
end