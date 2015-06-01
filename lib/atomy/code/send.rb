module Atomy
  module Code
    class Send
      attr_reader :receiver, :message, :arguments

      def initialize(receiver, message, arguments = [])
        @receiver = receiver
        @message = message
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

        gen.send(@message, @arguments.size)
      end
    end
  end
end
