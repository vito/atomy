module Atomo
  module AST
    class True < AST::Node
      Atomo::Parser.register self

      def self.rule_name
        "True"
      end

      def initialize
        @line = 1 # TODO
      end

      def self.grammar(g)
        g.true = g.str("True") { True.new }
      end

      def bytecode(g)
        pos(g)
        g.push :true
      end
    end
  end
end
