module Atomy
  module Code
    class Send
      def initialize(receiver, name, arguments = [])
        @receiver = receiver
        @name = name
        @arguments = arguments
      end

      def bytecode(gen, mod)
        if @receiver
          mod.compile(gen, @receiver)
        else
          gen.push_self
        end

        @arguments.each do |arg|
          mod.compile(gen, arg)
        end

        gen.allow_private unless @receiver

        gen.send(@name, @arguments.size)
      end
    end
  end
end
