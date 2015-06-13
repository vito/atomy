module Atomy
  module Code
    class ClassVariable
      attr_reader :name

      def initialize(name)
        @name = name
      end

      def bytecode(gen, mod)
        gen.push_scope
        gen.push_literal(:"@@#{@name}")
        gen.send(:class_variable_get, 1)
      end
    end
  end
end
