module Atomy
  module AST
    class Macro < Node
      children :pattern, :body
      generate

      def macro_pattern
        @macro_pattern ||= @pattern.macro_pattern
      end

      def prepared
        @prepared ||= @body.prepare_all
      end

      def bytecode(g)
        pos(g)

        Atomy::Macro.register(
          @pattern.class,
          macro_pattern,
          prepared,
          Atomy::CodeLoader.compiling
        )

        Atomy::CodeLoader.when_load << [self, true]
        Atomy::CodeLoader.when_run << [self, true]

        g.push_nil
      end

      def load_bytecode(g)
        pos(g)
        g.push_cpath_top
        g.find_const :Atomy
        g.find_const :Macro
        Atomy.const_from_string(g, @pattern.class.name)
        macro_pattern.construct(g)
        prepared.construct(g)
        g.push_scope
        g.send :active_path, 0
        g.send :register, 4
      end

      def prepare_all
        dup.tap do |x|
          x.body = x.body.prepare_all
        end
      end
    end
  end
end
