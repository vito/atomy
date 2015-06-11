require "atomy/compiler"
require "atomy/code/define"

module Atomy
  module Code
    class DefineFunction < Define
      def bytecode(gen, mod)
        var = assignment_local(gen, :"#{@name}:function")

        gen.push_rubinius
        gen.find_const(:BlockEnvironment)
        gen.find_const(:AsMethod)

        gen.push_rubinius
        gen.find_const(:BlockEnvironment)
        gen.send(:new, 0)

        gen.push_variables

        gen.push_cpath_top
        gen.find_const(:Atomy)
        gen.push_scope
        gen.push_literal(@name)
        push_branch(gen, mod)
        gen.send(:register_branch, 3)
        gen.send(:build, 0)

        gen.send(:under_context, 2)

        gen.send(:new, 1)

        var.set_bytecode(gen)
      end

      private

      def assignment_local(gen, name)
        var = gen.state.scope.search_local(name)

        if var && var.depth == 0
          var
        else
          gen.state.scope.new_local(name).nested_reference
        end
      end
    end
  end
end
