module Atomo
  module AST
    class Particle < AST::Node
      Atomo::Parser.register self

      def self.rule_name
        "particle"
      end

      def initialize(name)
        @name = name
        @line = 1 # TODO
      end

      def ==(b)
        b.kind_of?(Particle) and \
        @name == b.name
      end

      attr_reader :name

      def self.grammar(g)
        g.particle =
          g.seq("#", g.t(/[a-zA-Z][a-zA-Z0-9_]*/)) { |x| Particle.new(x) }
      end

      def bytecode(g)
        pos(g)
        g.push_literal @name.to_sym
      end
    end
  end
end
