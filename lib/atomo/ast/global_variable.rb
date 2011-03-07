module Atomo
  module AST
    class GlobalVariable < Rubinius::AST::GlobalVariableAccess
      include NodeLike

      attr_accessor :variable, :line
      attr_reader :name, :identifier

      def initialize(line, name)
        @name = ("$" + name).to_sym
        @identifier = name
        @line = line
      end

      def ==(b)
        b.kind_of?(GlobalVariable) and \
        @name == b.name
      end
    end
  end
end
