module Atomo
  module AST
    class Constant < Node
      attr_reader :chain

      def initialize(line, chain)
        @chain = Array(chain)
        @line = line
      end

      def ==(b)
        b.kind_of?(Constant) and \
        @chain == b.chain
      end

      def bytecode(g)
        pos(g)
        g.push_const @chain[0].to_sym
        @chain.drop(1).each do |s|
          g.find_const s.to_sym
        end
      end
    end
  end
end
