module Atomy
  module Code
    class Quote
      def initialize(node)
        @node = node
      end

      def bytecode(gen, mod)
        @node.construct(gen)
      end
    end
  end
end
