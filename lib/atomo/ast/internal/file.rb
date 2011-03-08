module Atomo
  module AST
    class File < Rubinius::AST::File
      include NodeLike

      def construct(g, d = nil)
        get(g)
        g.push_int @line
        g.send :new, 1
      end
    end
  end
end

