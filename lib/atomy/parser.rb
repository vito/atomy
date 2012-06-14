path = File.expand_path("../", __FILE__)

require path + "/atomy.kpeg.rb"

require path + "/ast/node"

Dir["#{path}/ast/**/*.rb"].sort.each do |f|
  require f
end

module Atomy
  class Parser
    include Atomy::AST

    attr_accessor :module

    attr_writer :callback

    def callback(x)
      if @callback
        @callback.call(x)
      else
        x
      end
    end

    def create(cls, *args)
      n = cls.new(*args)
      n.file = @module.file if @module
      n
    end

    def operator?(x)
      if @module
        !!@module.infix_info(x)
      end
    end

    def current_position(target=pos)
      cur_offset = 0
      cur_line = 0

      line_lengths.each do |len|
        cur_line += 1
        return [cur_line, target - cur_offset] if cur_offset + len > target
        cur_offset += len
      end

      [cur_line, cur_offset]
    end

    def line_lengths
      @line_lengths ||= lines.collect { |l| l.size }
    end

    def current_line(x=pos)
      current_position(x)[0]
    end

    def current_column(x=pos)
      current_position(x)[1]
    end

    def continue?(x)
      y = current_position
      y[0] >= x[0] && y[1] > x[1]
    end

    def private_target(line=0)
      Primitive.new(line, :self)
    end

    def resolve(a, e, chain)
      return [e, []] if chain.empty?

      b, *rest = chain

      if a && a.precedes?(b)
        [e, chain]
      else
        e2, *rest2 = rest
        r, rest3 = resolve(b, e2, rest2)
        resolve(a, Infix.new(e.line, e, r, b.name, b.private?), rest3)
      end
    end

    def set_lang(n)
      @_grammar_lang = require("#{n}/language/parser")::Parser.new(nil)
    end

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

