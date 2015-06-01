require "atomy/compiler"
require "atomy/pattern/message"

module Atomy
  module Code
    class DefineMethod
      def initialize(name, body, arguments = [], receiver = nil)
        @name = name
        @body = body
        @receiver = receiver
        @arguments = arguments
      end

      def bytecode(gen, mod)
        gen.push_cpath_top
        gen.find_const(:Atomy)

        gen.push_cpath_top
        gen.find_const(:Kernel)
        gen.send(:binding, 0)

        gen.push_literal(@name)

        gen.push_cpath_top
        gen.find_const(:Atomy)
        gen.find_const(:Pattern)
        gen.find_const(:Message)

        if @receiver
          mod.compile(gen, mod.pattern(@receiver))
        else
          gen.push_nil
        end

        @arguments.each do |a|
          mod.compile(gen, mod.pattern(a))
        end
        gen.make_array(@arguments.size)

        gen.send(:new, 2)

        @body.construct(gen) # TODO might as well push_literal

        gen.push_literal(mod) # TODO totally cheating; this can't be marshalled

        gen.send(:define_branch, 5)
      end
    end
  end
end
