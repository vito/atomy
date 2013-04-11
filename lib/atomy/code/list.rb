module Atomy
  module Code
    class List
      def initialize(elements)
        @elements = elements
      end

      def bytecode(gen, mod)
        @elements.each do |e|
          mod.compile(gen, e)
        end

        gen.make_array(@elements.size)
      end
    end
  end
end
