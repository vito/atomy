require "atomy/compiler"
require "atomy/code/define"

module Atomy
  module Code
    class DefineMethod < Define
      def bytecode(gen, mod)
        gen.push_cpath_top
        gen.find_const(:Atomy)
        gen.push_cpath_top
        gen.find_const(:Kernel)
        gen.send(:binding, 0)
        gen.push_literal(@name)
        push_branch(gen, mod)
        gen.send(:define_branch, 3)
      end
    end
  end
end
