module Atomy
  module Code
    class Variable
      def initialize(name)
        @name = name
      end

      def bytecode(gen, mod)
        if local = gen.state.scope.search_local(@name)
          if local.depth > 0
            gen.push_local_depth(local.slot, local.depth)
          else
            gen.push_local(local.slot)
          end
        else
          gen.push_self
          gen.allow_private
          gen.send(@name, 0)
        end
      end
    end
  end
end
