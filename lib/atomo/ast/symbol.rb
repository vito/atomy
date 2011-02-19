module Atomo
  module AST
    class Symbol < AST::Node
      Atomo::Parser.register self

      def self.rule_name
        "symbol"
      end

      def initialize(name)
        @name = name
        @line = 1 # TODO
      end

      attr_reader :name

      def self.grammar(g)
        g.symbol = g.seq("@", g.t(/[a-zA-Z][a-zA-Z0-9_]*/)) { |x| Symbol.new(x) }
      end

      def bytecode(g)
        pos(g)
        g.push_literal @name.to_sym
      end
    end
  end
end
