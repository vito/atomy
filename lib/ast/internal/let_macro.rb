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
          next unless meth = Atomy::Macro::Environment.let[m.pattern.method_name]

          Atomy::Macro::Environment.singleton_class.send(
            :define_method,
            defined[m.pattern.method_name],
            meth.pop
          )
        end
      end
    end
  end
end
