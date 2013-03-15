require "atomy/code"

module Atomy
  class StringLiteral < Code
    def initialize(value)
      @value = value
    end

    def bytecode(gen, mod)
      gen.push_literal(@value)
      gen.string_dup
    end
  end
end
