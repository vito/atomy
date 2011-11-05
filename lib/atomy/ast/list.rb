module Atomy
  module AST
    class List < Node
      children [:elements]
      generate

      def bytecode(g)
        pos(g)

        g.push_cpath_top
        g.find_const :Hamster

        @elements.each do |e|
          e.compile(g)
        end

        g.send :list, @elements.size
        # g.make_array @elements.size
      end
    end
  end
end
