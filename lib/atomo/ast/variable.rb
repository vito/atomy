module Atomo
  module AST
    class Variable < Node
      attr_accessor :line

      Atomo::Parser.register self

      def self.rule_name
        "variable"
      end

      def initialize(name)
        @name = name
        @line = 1 # TODO
      end

      def ==(b)
        b.kind_of?(Variable) and \
        @name == b.name
      end

      attr_reader :name

      def self.grammar(g)
        g.variable = g.seq(:identifier) do |str|
          Variable.new(str)
        end
      end

      def bytecode(g)
        pos(g)

        var = g.state.scope.search_local(@name)
        if var
          var.get_bytecode(g)
        else
          g.push_self
          g.send @name.to_sym, 0, true
        end
      end
    end
  end
end
