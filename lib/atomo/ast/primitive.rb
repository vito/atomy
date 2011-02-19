module Atomo
  module AST
    class Primitive < AST::Node
      Atomo::Parser.register self

      def self.rule_name
        "primitive"
      end

      def initialize(value)
        @value = value
        @line = 1 # TODO
      end

      attr_reader :value

      def self.grammar(g)
        g.number = g.reg(/0|([1-9][0-9]*)/) do |i|
          Primitive.new i.to_i
        end

        g.true = g.str("True") { Primitive.new :true }
        g.false = g.str("False") { Primitive.new :false }

        g.self = g.str("self") { Primitive.new :self }

        g.nil = g.str("nil") { Primitive.new :nil }
      end

      def bytecode(g)
        pos(g)
        g.push @value
      end
    end
  end
end
