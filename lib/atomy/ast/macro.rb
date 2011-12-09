module Atomy
  module AST
    class Macro < Node
      children :pattern, :body
      generate

      def bytecode(g)
        @pattern.define_macro(@body, Atomy::CodeLoader.compiling)

        pos(g)
        @pattern.construct(g)
        @body.construct(g)
        g.push_scope
        g.send :active_path, 0
        g.send :define_macro, 2
      end
    end
  end
end
