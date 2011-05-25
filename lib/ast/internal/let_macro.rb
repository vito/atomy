module Atomy
  module AST
    class LetMacro < Node
      children :body, [:macros]
      generate

      def bytecode(g)
        pos(g)

        defined = {}
        @macros.each do |m|
          defined[m.pattern.method_name] =
            m.pattern.register_macro m.body, true
        end

        @body.compile(g)

        @macros.each do |m|
          meth = m.pattern.method_name
          name = defined[meth]

          Atomy::Macro::Environment.singleton_class.remove_method(name)

          next unless lets = Atomy::Macro::Environment.let[meth]

          lets.pop

          Atomy::Macro::Environment.let.delete(meth) if lets.empty?
        end
      end
    end
  end
end
