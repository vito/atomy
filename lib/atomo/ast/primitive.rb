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

      def ==(b)
        b.kind_of?(Primitive) and \
        @value == b.value
      end

      attr_reader :value

      def self.grammar(g)
        g.number = g.reg(/[\+\-]?\d+(\.\d+)?[eE][\+\-]?\d+/) do |f|
          Primitive.new f.to_f
        end | g.reg(/[\+\-]?0[oO][0-7]+/) do |i|
          Primitive.new i.to_i 8
        end | g.reg(/[\+\-]?0[xX][\da-fA-F]+/) do |i|
          Primitive.new i.to_i 16
        # TODO: rationals, once rubinius has them
        end | g.reg(/[\+\-]?\d+/) do |i|
          Primitive.new i.to_i
        end

        g.true = g.str("True") { Primitive.new :true }
        g.false = g.str("False") { Primitive.new :false }

        g.self = g.str("self") { Primitive.new :self }

        g.nil = g.str("nil") { Primitive.new :nil }
      end

      def bytecode(g)
        pos(g)

        if @value.kind_of? Float
          g.push_unique_literal @value
        else
          g.push @value
        end
      end
    end
  end
end
