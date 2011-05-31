module Atomy
  module AST
    class LetMacro < Node
      children :body, [:macros]
      generate

      def bytecode(g)
        pos(g)
        setup_macros
        @body.compile(g)
        unwind_macros
      end

      def setup_macros
        @defined = {}

        @macros.each do |m|
          @defined[m.pattern] =
            Atomy::Macro.register(
              m.pattern.class,
              m.macro_pattern,
              m.body,
              Atomy::CodeLoader.compiling,
              true
            )
        end
      end

      def unwind_macros
        @macros.reverse_each do |m|
          pat = m.pattern
          name = @defined[pat]

          pat.class.remove_method(name)

          next unless lets = Atomy::Macro::Environment.let[pat.class]

          lets.delete(name)

          Atomy::Macro::Environment.let.delete(pat.class) if lets.empty?
        end
      end

      def prepare_all
        dup.tap do |y|
          setup_macros
          y.body = y.body.prepare_all
          unwind_macros
        end
      end
    end
  end
end
