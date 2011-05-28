module Atomy
  module AST
    class Macro < Node
      children :pattern, :body
      generate

      def macro_pattern
        @macro_pattern ||= @pattern.macro_pattern
      end

      def bytecode(g)
        if @pattern.namespace_symbol
          Atomy::Namespace.register(
            @pattern.namespace_symbol,
            Atomy::Namespace.define_target
          )

          registerer =
            Atomy::AST::Send.new(
              0,
              Atomy::AST::Variable.new(0, "register"),
              Atomy::AST::ScopedConstant.new(
                0,
                Atomy::AST::ToplevelConstant.new(
                  0,
                  "Atomy"
                ),
                "Namespace"
              ),
              [ @pattern.namespace_symbol.to_node,
                Atomy::Namespace.define_target.to_node
              ]
            )

          Atomy::CodeLoader.when_load << [registerer, true]
          Atomy::CodeLoader.when_run << [registerer, true]
        end

        # register macro during compilation too.
        Atomy::Macro.register(
          @pattern.class,
          macro_pattern,
          @body,
          Atomy::CodeLoader.compiling
        )

        done = g.new_label
        skip = g.new_label

        g.push_cpath_top
        g.find_const :Atomy
        g.find_const :CodeLoader
        g.send :compiled?, 0
        g.git skip

        load_bytecode(g)
        g.goto done

        skip.set!
        g.push_nil

        done.set!
      end

      def load_bytecode(g)
        pos(g)
        g.push_cpath_top
        g.find_const :Atomy
        g.find_const :Macro
        Atomy.const_from_string(g, @pattern.class.name)
        macro_pattern.construct(g)
        @body.construct(g)
        g.push_scope
        g.send :active_path, 0
        g.send :register, 4
      end
    end
  end
end
