module Atomo
  module AST
    class Operator < Node
      attr_reader :operators, :associativity, :precedence

      def initialize(line, os, a, p)
        @line = line
        @operators = os
        @associativity = a
        @precedence = p
      end

      def construct(g, d)
        get(g)
        g.push_int @line
        @operators.each do |o|
          g.push_literal o
        end
        g.make_array @operators.size
        g.push_literal @associativity
        g.push_int @precedence
        g.send :new, 4
      end

      def ==(b)
        b.kind_of?(Operator) and \
        @operators == b.operators and \
        @associativity == b.associativity and \
        @precedence == b.precedence
      end

      def recursively(stop = nil, &f)
        f.call(self)
      end

      def bytecode(g)
        pos(g)
        g.push_const :Atomo
        g.find_const :Macro
        @operators.each do |o|
          g.push_literal o
        end
        g.make_array @operators.size
        g.push_literal @associativity
        g.push_int @precedence
        g.send :set_op_info, 3
      end
    end
  end
end
