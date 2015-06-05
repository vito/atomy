module Atomy
  module Code
    class False
      def bytecode(gen, mod)
        gen.push_false
      end
    end
  end
end
