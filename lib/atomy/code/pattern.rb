module Atomy
  module Code
    class Pattern
      attr_reader :node, :locals

      def initialize(node, locals)
        @node = node
        @locals = locals
      end

      def bytecode(gen, mod)
        mod.compile(gen, @node)
      end
    end
  end
end
