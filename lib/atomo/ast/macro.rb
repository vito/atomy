module Atomo
  module AST
    class Macro < Node
      children :pattern, :body
      generate

      def bytecode(g)
        pos(g)
        @pattern.construct(g, nil)
        @body.construct(g, nil)
        g.send :register_macro, 1
      end
    end
  end
end
