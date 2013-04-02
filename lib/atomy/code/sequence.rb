module Atomy
  module Code
    class Sequence
      def initialize(nodes)
        @nodes = nodes
      end

      def bytecode(gen, mod)
        if @nodes.empty?
          gen.push_nil
          return
        end

        @nodes.each.with_index do |node, idx|
          gen.pop unless idx == 0
          mod.compile(gen, node)
        end
      end
    end
  end
end
