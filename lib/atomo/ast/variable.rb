module Atomo
  module AST
    class Variable < AST::Node
      attr_accessor :variable, :line

      Atomo::Parser.register self

      def self.rule_name
        "variable"
      end

      def initialize(name)
        @name = name
        @variable = nil
        @line = 1 # TODO
      end

      attr_reader :name

      def self.grammar(g)
        g.variable = g.lit(/[a-z][a-zA-Z0-9_]*/) do |str|
          Variable.new(str)
        end
      end

      def bytecode(g)
        pos(g)

        unless @variable
          # sets @variable
          g.state.scope.assign_local_reference self
        end

        @variable.get_bytecode(g)
      end
    end
  end
end