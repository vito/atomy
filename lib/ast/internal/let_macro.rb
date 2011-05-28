module Atomy
  module AST
    class LetMacro < Node
      children :body, [:macros]
      generate

      def bytecode(g)
        pos(g)

        defined = {}
        @macros.each do |m|
          defined[m.pattern] =
            Atomy::Macro.register(
              m.pattern.class,
              m.macro_pattern,
              m.body,
              Atomy::CodeLoader.compiling,
              true
            )
        end

        @body.compile(g)

        @macros.each do |m|
          pat = m.pattern
          name = defined[pat]

          pat.class.remove_method(name)

          next unless lets = Atomy::Macro::Environment.let[pat.class]

          lets.delete(name)

          Atomy::Macro::Environment.let.delete(pat.class) if lets.empty?
        end
      end
    end
  end
end
