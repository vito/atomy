module Atomo
  module AST
    class Number < AST::Node
      Atomo::Parser.register self

      def self.rule_name
        "number"
      end

      def initialize(value)
        @value = value
        @line = 1 # TODO
      end

      attr_reader :value

      def self.grammar(g)
        g.number = g.reg(/0|([1-9][0-9]*)/) do |i|
          Number.new(i.to_i)
        end
      end

      def bytecode(g)
        pos(g)
        g.push @value
      end
    end
  end
end
