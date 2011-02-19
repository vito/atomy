module Atomo
  module AST
    class Nil < AST::Node
      Atomo::Parser.register self

      def self.rule_name
        "nil"
      end

      def initialize
        @line = 1 # TODO
      end

      def self.grammar(g)
        g.nil = g.str("nil") { Nil.new }
      end

      def bytecode(g)
        pos(g)
        g.push :nil
      end
    end
  end
end
