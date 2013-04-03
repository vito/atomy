require "atomy/compiler"
require "atomy/pattern/message"

module Atomy
  module Code
    class DefineMethod
      def initialize(name, body, receiver = nil, arguments = [])
        @name = name
        @body = body
        @receiver = receiver
        @arguments = arguments
      end

      def bytecode(gen, mod)
        blk = Atomy::Compiler.generate(mod.file) do |blk|
          blk.name = @name
          blk.state.scope.parent = gen.state.scope
          blk.splat_index = 0
          blk.total_args = 0
          blk.required_args = 0

          blk.push_local(0)
          blk.state.scope.new_local(:__arguments__)
          message_pattern(mod).deconstruct(blk)

          mod.compile(blk, @body)
        end

        gen.push_cpath_top
        gen.find_const(:Atomy)
        gen.push_scope
        gen.send(:for_method_definition, 0)
        gen.push_literal(@name)

        gen.push_cpath_top
        gen.find_const(:Atomy)
        gen.find_const(:Pattern)
        gen.find_const(:Message)

        if @receiver
          push_pattern(gen, @receiver)
        else
          gen.push_nil
        end

        @arguments.each do |a|
          push_pattern(gen, a)
        end
        gen.make_array(@arguments.size)

        gen.send(:new, 2)

        gen.create_block(blk)

        gen.send_with_block(:define_branch, 3)
      end

      private

      def push_pattern(gen, pat)
        gen.push_self
        pat.construct(gen)
        gen.send(:pattern, 1, true)
      end

      def message_pattern(mod)
        Atomy::Pattern::Message.new(
          @receiver && mod.pattern(@receiver),
          @arguments.collect { |a| mod.pattern(a) })
      end
    end
  end
end
