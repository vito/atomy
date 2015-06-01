module Atomy
  module Code
    class Assign
      def initialize(name, value)
        @name = name
        @value = value
      end

      def bytecode(gen, mod)
        mod.compile(gen, @value)
        assignment_local(gen, @name).set_bytecode(gen)
      end

      def assignment_local(gen, name, set = false)
        var = gen.state.scope.search_local(name)

        if var && (set || var.depth == 0)
          var
        else
          gen.state.scope.new_local(name).nested_reference
        end
      end
    end
  end
end
