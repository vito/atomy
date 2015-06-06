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
        if fun = gen.state.scope.search_local(:"#{@message}:function")
          invoke_function(gen, mod, fun)
        else
          invoke_method(gen, mod)
        end
      end

      private

      def invoke_function(gen, mod, fun)
        fun.get_bytecode(gen)

        gen.dup
        gen.send(:compiled_code, 0)
        gen.send(:scope, 0)

        if @receiver
          mod.compile(gen, @receiver)
        else
          gen.push_self
        end

        gen.swap

        # visibility_scope
        gen.push_false

        @arguments.each do |arg|
          mod.compile(gen, arg)
        end

        gen.send(:call_under, @arguments.size + 3)
      end

      def invoke_method(gen, mod)
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
