module Atomy
  module Code
    class Constant
      def initialize(name, parent = nil)
        @name = name
        @parent = parent
      end
      
      def bytecode(gen, mod)
        if @parent
          mod.compile(gen, @parent)
          gen.find_const(@name)
        else
          gen.push_const(@name)
        end
      end
    end
  end
end
