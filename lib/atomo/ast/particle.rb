module Atomo
  module AST
    class Particle < Node
      attr_reader :name

      def initialize(line, name)
        @name = name
        @line = line
      end

      def construct(g, d = nil)
        get(g)
        g.push_int @line
        g.push_literal @name
        g.send :new, 2
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
