module Atomy
  module Code
    class Nil
      def bytecode(gen, mod)
        gen.push_nil
      end
    end
  end
end
