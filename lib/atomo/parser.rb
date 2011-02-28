# Introduce our vendored kpeg
$:.unshift File.expand_path("../../vendor/kpeg/lib", __FILE__)

require "lib/atomo/atomo.kpeg.rb"

module Atomo
  class Parser
    def self.parse_string(source)
      p = new(source)
      raise ParseError.new(p) unless p.parse
      AST::Tree.new(p.result)
    end

    def self.parse_file(name)
      p = new(File.open(name, "rb").read)
      raise ParseError.new(p) unless p.parse
      AST::Tree.new(p.result)
    end

    class ParseError < RuntimeError
      def initialize(parser)
        super parser.error_expectation
        @parser = parser
        @match = parser.result
      end

      attr_reader :parser, :match
    end
  end

  path = File.expand_path("../ast", __FILE__)

  require path + "/node"

  Dir["#{path}/**/*.rb"].sort.each do |f|
    require f
  end
end

