module Atomo
  module AST
    class ClassVariable < Rubinius::AST::ClassVariableAccess
      include NodeLike

      attr_accessor :variable, :line
      attr_reader :name, :identifier

      def initialize(line, name)
        @name = ("@@" + name).to_sym
        @identifier = name
        @line = line
      end

      def construct(g, d = nil)
        get(g)
        g.push_int @line
        g.push_literal @identifier
        g.send :new, 2
      end

      def ==(b)
        b.kind_of?(ClassVariable) and \
        @name == b.name
      end
    end
  end
end
