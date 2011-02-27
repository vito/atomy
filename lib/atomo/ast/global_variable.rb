module Atomo
  module AST
    class GlobalVariable < Rubinius::AST::GlobalVariableAccess
      include NodeLike

      attr_accessor :variable, :line

      Atomo::Parser.register self

      def self.rule_name
        "global_variable"
      end

      def initialize(name)
        @name = name
        @line = 1 # TODO
      end

      def ==(b)
        b.kind_of?(GlobalVariable) and \
        @name == b.name
      end

      attr_reader :name

      def self.grammar(g)
        g.global_variable = g.seq("$", g.t(:identifier)) do |str|
          GlobalVariable.new("$" + str)
        end
      end
    end
  end
end
