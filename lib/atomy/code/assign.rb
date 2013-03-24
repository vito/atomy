module Atomy
  module Code
    class Assign
      def initialize(pattern, value)
        @pattern = pattern
        @value = value
      end

      def bytecode(gen, mod)
        pat = mod.pattern(@pattern)
        pat.node = @pattern
        mod.compile(gen, @value)
        pat.match(gen, mod)
      end
    end
  end
end
