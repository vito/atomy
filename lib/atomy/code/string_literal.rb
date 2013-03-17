module Atomy
  module Code
    class StringLiteral
      def initialize(value)
        @value = value
      end

      def bytecode(gen, mod)
        gen.push_literal(@value)
        gen.string_dup
      end
    end
  end
end
