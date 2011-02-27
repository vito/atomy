module Atomo
  module AST
    class ClassVariable < Rubinius::AST::ClassVariableAccess
      include NodeLike

      attr_accessor :variable, :line

      Atomo::Parser.register self

      def self.rule_name
        "class_variable"
      end

      def initialize(name)
        @name = name.to_sym
        @line = 1 # TODO
      end

      def ==(b)
        b.kind_of?(ClassVariable) and \
        @name == b.name
      end

      attr_reader :name

      def self.grammar(g)
        g.class_variable = g.seq("@@", g.t(:identifier)) do |str|
          ClassVariable.new("@@" + str)
        end
      end
    end
  end
end
