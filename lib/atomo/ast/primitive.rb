module Atomo
  module AST
    class Primitive < Node
      attr_reader :value

      def initialize(value)
        @value = value
        @line = 1 # TODO
      end

      def ==(b)
        b.kind_of?(Primitive) and \
        @value == b.value
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
