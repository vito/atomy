module Atomo
  module AST
    class List < Node
      children [:elements]
      generate

      def bytecode(g)
        pos(g)

        @elements.each do |e|
          e.bytecode(g)
        end

        g.make_array @elements.size
      end
    end
  end
end
