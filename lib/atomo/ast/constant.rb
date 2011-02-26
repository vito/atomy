module Atomo
  module AST
    class Constant < AST::Node
      Atomo::Parser.register self

      def self.rule_name
        "constant"
      end

      def initialize(chain)
        @chain = chain
        @line = 1 # TODO
      end

      def ==(b)
        b.kind_of?(Constant) and \
        @chain == b.chain
      end

      attr_reader :chain

      def self.grammar(g)
        g.constant = g.seq(
          g.lit(/[A-Z][a-zA-Z0-9_]*/),
          g.kleene(g.seq("::", g.t(/[A-Z][a-zA-Z0-9_]*/)))
        ) do |main, subs|
          Constant.new([main] + Array(subs))
        end
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
