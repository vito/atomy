require "atomy/grammar"

module Atomy
  module Parser
    extend self

    def parse_file(file)
      parse_string(File.read(file))
    end

    def parse_string(source)
      grammar = Atomy::Grammar.new(source)

      grammar.raise_error unless grammar.parse

      grammar.result
    rescue KPeg::CompiledParser::ParseError => e
      raise SyntaxError, e.to_s
    end
  end
end
