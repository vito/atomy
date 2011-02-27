module Atomo
  module AST
    class InstanceVariable < Rubinius::AST::InstanceVariableAccess
      include NodeLike

      attr_accessor :variable, :line

      Atomo::Parser.register self

      def self.rule_name
        "instance_variable"
      end

      def initialize(name)
        @name = name.to_sym
        @line = 1 # TODO
      end

      def ==(b)
        b.kind_of?(InstanceVariable) and \
        @name == b.name
      end

      attr_reader :name

      def self.grammar(g)
        g.instance_variable = g.seq("@", g.t(:identifier)) do |str|
          InstanceVariable.new("@" + str)
        end
      end
    end
  end
end
