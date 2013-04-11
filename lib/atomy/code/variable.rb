module Atomy
  module Code
    class Variable
      def initialize(name)
        @name = name
      end

      def bytecode(gen, mod)
        if local = gen.state.scope.search_local(@name)
          local.get_bytecode(gen)
        else
          gen.push_self
          gen.allow_private
          gen.send(@name, 0)
        end
      end
    end
  end
end
