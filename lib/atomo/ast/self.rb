module Atomo
  module AST
    class Self < AST::Node
      Atomo::Parser.register self

      def self.rule_name
        "self"
      end

      def initialize
        @line = 1 # TODO
      end

      def self.grammar(g)
        g.self = g.str("self") { Self.new }
      end

      def bytecode(g)
        pos(g)
        g.push :self
      end
    end
  end
end
