module Atomy
  module Code
    class Send
      attr_reader :receiver, :message, :arguments

      def initialize(receiver, message, arguments = [], block = nil)
        @receiver = receiver
        @message = message
        @arguments = arguments
        @block = block
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

        if @block
          mod.compile(gen, @block)
          gen.send_with_block(@message, @arguments.size)
        else
          gen.send(@message, @arguments.size)
        end
      end
    end
  end
end
