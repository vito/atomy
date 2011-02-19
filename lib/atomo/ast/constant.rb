module Atomo
  module AST
    class Constant < AST::Node
      Atomo::Parser.register self

      def self.rule_name
        "constant"
      end

      def initialize(name)
        @name = name
        @line = 1 # TODO
      end

      attr_reader :name

      def self.grammar(g)
        g.constant = g.lit(/[A-Z][a-zA-Z0-9_]*/) do |str|
          Constant.new(str)
        end
      end

      def bytecode(g)
        pos(g)
        g.push_const @name.to_sym
      end
    end
  end
end