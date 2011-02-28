module Atomo
  module AST
    class Particle < Node
      attr_reader :name

      def initialize(name)
        @name = name
        @line = 1 # TODO
      end

      def ==(b)
        b.kind_of?(Particle) and \
        @name == b.name
      end

      def bytecode(g)
        pos(g)
        g.push_literal @name.to_sym
      end
    end
  end
end
