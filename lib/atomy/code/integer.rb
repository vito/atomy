module Atomy
  module Code
    class Integer
      def initialize(value)
        @value = value
      end

      def bytecode(gen, mod)
        gen.push_int(@value)
      end
    end
  end
end
