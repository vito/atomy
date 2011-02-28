module Atomo
  module AST
    class InstanceVariable < Rubinius::AST::InstanceVariableAccess
      include NodeLike

      attr_accessor :variable, :line
      attr_reader :name

      def initialize(line, name)
        @name = name.to_sym
        @line = line
      end

      def ==(b)
        b.kind_of?(InstanceVariable) and \
        @name == b.name
      end
    end
  end
end
