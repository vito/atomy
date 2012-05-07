module Atomy
  module AST
    class List < Node
      children [:elements]

      def bytecode(g, mod)
        pos(g)

        @elements.each do |e|
          mod.compile(g, e)
        end

        g.make_array @elements.size
      end
    end
  end
end
