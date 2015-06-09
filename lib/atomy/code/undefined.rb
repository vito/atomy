module Atomy
  module Code
    class Undefined
      def bytecode(gen, mod)
        gen.push_undef
      end
    end
  end
end
