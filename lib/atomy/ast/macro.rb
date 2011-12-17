module Atomy
  module AST
    class Macro < Node
      children :pattern, :body
      generate

      def bytecode(g)
        Atomy::CodeLoader.module.define_macro(@pattern, @body, Atomy::CodeLoader.compiling)

        pos(g)
        g.push_self
        @pattern.construct(g)
        @body.construct(g)
        g.push_scope
        g.send :active_path, 0
        g.send :define_macro, 3
      end
    end
  end
end
