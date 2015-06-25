module Atomy
  module Code
    class Pattern
      attr_reader :node

      def initialize(node)
        @node = node
      end

      def bytecode(gen, mod)
        mod.compile(gen, @node)
      end

      # [value, pattern] on stack
      def assign(gen)
      end

      def splat?
        false
      end
    end
  end
end
