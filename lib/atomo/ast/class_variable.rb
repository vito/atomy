module Atomo
  module AST
    class ClassVariable < Rubinius::AST::ClassVariableAccess
      include NodeLike

      attr_accessor :variable, :line
      attr_reader :name

      def initialize(line, name)
        @name = name.to_sym
        @line = line
      end

      def ==(b)
        b.kind_of?(ClassVariable) and \
        @name == b.name
      end
    end
  end
end
