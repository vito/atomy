module Atomy
  module AST
    class File < Node
      generate

      def bytecode(g, mod)
        pos(g)
        g.push_scope
        g.send :active_path, 0
      end
    end
  end
end

