# Introduce our vendored kpeg
$:.unshift File.expand_path("../../vendor/kpeg/lib", __FILE__)

require "kpeg"

module Atomo
  class Parser
    @nodes = []
    def self.register(node)
      @nodes << node
    end

    def self.to_kpeg
      gram = KPeg::Grammar.new

      @nodes.each do |node|
        node.grammar(gram)
      end

      AST.grammar(gram)

      gram
    end

    def self.parse_string(source)
      x = new(source).parse
      def x.bytecode(g)
        each { |n| n.bytecode(g) }
      end
      x
    end

    def self.parse_file(name)
      x = new(File.open(name, "rb").read).parse
      def x.bytecode(g)
        each { |n| n.bytecode(g) }
      end
      x
    end

    def initialize(str)
      @parser = KPeg::Parser.new(str, Grammar)
    end

    class ParseError < RuntimeError
      def initialize(parser, match)
        super parser.error_expectation
        @parser = parser
        @match = match
      end

      attr_reader :parser, :match
    end

    def parse(rule = nil)
      @last_match = match = @parser.parse(rule ? rule.to_s : nil)

      if @parser.failed?
        raise ParseError.new(@parser, match)
      end

      return match.value if match
    end

    attr_reader :last_match

    path = File.expand_path("../ast", __FILE__)

    require path + "/global"
    require path + "/node"

    Dir["#{path}/*.rb"].sort.each do |f|
      require path + "/#{File.basename f}"
    end

    Grammar = to_kpeg
  end
end

