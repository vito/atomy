module Atomy
  module AST
    class Macro < Node
      children :pattern, :body
      generate

      def bytecode(g)
        # register macro during compilation too.
        @pattern.register_macro @body

        pos(g)
        @pattern.construct(g)
        @body.construct(g)
        g.send :register_macro, 1
      end
    end
  end
end
