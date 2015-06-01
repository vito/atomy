module Atomy
  module Code
    class Symbol
      def initialize(value)
        @value = value
      end

      def bytecode(gen, mod)
        gen.push_literal(@value)
      end
    end
  end
end
