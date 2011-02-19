module Atomo
  module AST
    class False < AST::Node
      Atomo::Parser.register self

      def self.rule_name
        "False"
      end

      def initialize
        @line = 1 # TODO
      end

      def self.grammar(g)
        g.false = g.str("False") { False.new }
      end

      def bytecode(g)
        pos(g)
        g.push :false
      end
    end
  end
end
