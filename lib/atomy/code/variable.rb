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
          Send.new(nil, @name).bytecode(gen, mod)
        end
      end
    end
  end
end
