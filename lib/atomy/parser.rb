base = File.expand_path "../", __FILE__

require base + "/atomy.kpeg.rb"

module Atomy
  class Parser
    class Operator
      def initialize(mod, name, priv = false)
        @module = mod
        @name = name
        @private = priv
      end

      attr_reader :name
      attr_writer :private

      def private?
        @private
      end

      def precedence
        op_info(@name)[:precedence] || 60
      end

      def associativity
        op_info(@name)[:associativity] || :left
      end

      def precedes?(b)
        precedence > b.precedence ||
          precedence == b.precedence &&
          associativity == :left
      end

      private

      def op_info(op)
        @module.infix_info(op) || {}
      end
    end

    def self.parse_node(source)
      p = new(source)
      p.raise_error unless p.parse("one_expression")
      p.result
    end

    def self.parse_string(source, mod = nil, &callback)
      p = new(source)
      p.module = mod
      p.callback = callback
      p.raise_error unless p.parse
      AST::Tree.new(0, p.result)
    end

    def self.parse_file(name, mod = nil, &callback)
      parse_string(File.open(name, "rb", &:read), mod, &callback)
    end
  end
end

