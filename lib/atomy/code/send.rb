require "atomy/code"

module Atomy
  class Send < Code
    def initialize(receiver, name, arguments = [])
      @receiver = receiver
      @name = name
      @arguments = arguments
    end

    def bytecode(gen, mod)
      if @receiver
        mod.compile(gen, @receiver)
      else
        gen.allow_private
        gen.push_self
      end

      @arguments.each do |arg|
        mod.compile(gen, arg)
      end

      gen.send(@name, @arguments.size)
    end
  end
end
