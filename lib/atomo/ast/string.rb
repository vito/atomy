module Atomo
  module AST
    class String < AST::Node
      Atomo::Parser.register self

      def self.rule_name
        "string"
      end

      def initialize(value)
        @value = value
        @line = 1 # TODO
      end

      def ==(b)
        b.kind_of?(String) and \
        @value == b.value
      end

      attr_reader :value

      def self.grammar(g)
        escapes = g.str("\\\"") { "\""  } \
          | g.str('\n') { "\n" } \
          | g.str('\r') { "\r" } \
          | g.str('\t') { "\t" } \
          | g.str('\\\\') { "\\" }
        not_quote = g.many(g.any(escapes, /[^"]/)) { |*a| a.join }
        g.string = g.seq("\"", g.t(not_quote), "\"") do |str|
          String.new(str)
        end
      end

      def bytecode(g)
        pos(g)
        g.push_literal @value
        g.string_dup
      end
    end
  end
end
