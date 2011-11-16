module Atomy
  module AST
    class Macro < Node
      children :pattern, :body
      generate

      def bytecode(g)
        pos(g)

        @pattern.define_macro(@body)

        Atomy::CodeLoader.when_load << [self, true]
        Atomy::CodeLoader.when_run << [self, true]

        g.push_nil
      end

      def load_bytecode(g)
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
