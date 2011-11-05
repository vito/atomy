module Atomy
  module AST
    class Macro < Node
      children :pattern, :body
      generate

      def prepared
        @prepared ||= @body.prepare_all
      end

      def bytecode(g)
        pos(g)

        @pattern.define_macro(prepared)

        Atomy::CodeLoader.when_load << [self, true]
        Atomy::CodeLoader.when_run << [self, true]

        g.push_nil
      end

      def load_bytecode(g)
        pos(g)
        @pattern.construct(g)
        prepared.construct(g)
        g.push_scope
        g.send :active_path, 0
        g.send :define_macro, 2
      end

      def prepare_all
        dup.tap do |x|
          x.body = x.body.prepare_all
        end
      end
    end
  end
end
