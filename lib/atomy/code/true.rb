module Atomy
  module Code
    class True
      def bytecode(gen, mod)
        gen.push_true
      end
    end
  end
end
