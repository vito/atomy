module Atomy
  module Code
    class Send
      attr_reader :receiver, :message, :arguments, :proc_argument, :block

      def initialize(receiver, message, arguments = [], splat_argument = nil, proc_argument = nil, block = nil)
        @receiver = receiver
        @message = message
        @arguments = arguments
        @splat_argument = splat_argument
        @proc_argument = proc_argument
        @block = block
      end

      def bytecode(gen, mod)
        flocal = gen.state.scope.search_local(:"#{@message}:function")

        if @receiver.nil? && flocal
          invoke_function(gen, mod, flocal)
        else
          invoke_method(gen, mod)
        end
      end

      private

      def invoke_function(gen, mod, flocal)
        flocal.get_bytecode(gen)

        gen.dup
        gen.send(:block_env, 0)
        gen.send(:lexical_scope, 0)
        gen.send(:module, 0)

        gen.push_literal(@message)

        gen.swap

        gen.push_self

        @arguments.each do |arg|
          mod.compile(gen, arg)
        end
        gen.make_array(@arguments.size)

        if @splat_argument
          mod.compile(gen, @splat_argument)
          gen.send(:+, 1)
        end

        if @proc_argument
          push_proc_argument(gen, mod)
        elsif @block
          mod.compile(gen, @block)
        else
          gen.push_nil
        end

        gen.send(:invoke, 5)
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

        if @splat_argument
          mod.compile(gen, @splat_argument)
          if @proc_argument
            push_proc_argument(gen, mod)
          elsif @block
            mod.compile(gen, @block)
          else
            gen.push_nil
          end
          gen.allow_private unless @receiver
          gen.send_with_splat(@message, @arguments.size)
        elsif @proc_argument
          push_proc_argument(gen, mod)
          gen.allow_private unless @receiver
          gen.send_with_block(@message, @arguments.size)
        elsif @block
          mod.compile(gen, @block)
          gen.allow_private unless @receiver
          gen.send_with_block(@message, @arguments.size)
        else
          gen.allow_private unless @receiver
          gen.send(@message, @arguments.size)
        end

        def push_proc_argument(gen, mod)
          nil_proc_arg = gen.new_label
          mod.compile(gen, @proc_argument)
          gen.dup
          gen.goto_if_nil(nil_proc_arg)
          gen.push_cpath_top
          gen.find_const(:Proc)
          gen.swap
          gen.send(:__from_block__, 1)
          nil_proc_arg.set!
        end
      end
    end
  end
end
