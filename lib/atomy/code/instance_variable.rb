module Atomy
  module Code
    class InstanceVariable
      attr_reader :name

      def initialize(name)
        @name = name
      end

      def bytecode(gen, mod)
        gen.push_ivar(:"@#{@name}")
      end
    end
  end
end
