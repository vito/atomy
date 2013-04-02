module Atomy
  module Code
    class Self
      def bytecode(gen, mod)
        gen.push_self
      end
    end
  end
end
