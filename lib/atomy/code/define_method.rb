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
        blk = build_branch(gen, mod)

        gen.push_cpath_top
        gen.find_const(:Atomy)
        push_target(gen, mod)
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

      def build_branch(gen, mod)
        Atomy::Compiler.generate(mod.file) do |blk|
          blk.name = @name
          blk.state.scope.parent = gen.state.scope
          blk.required_args = blk.total_args = @arguments.size

          @arguments.each.with_index do |a, i|
            blk.state.scope.new_local(:"arg:#{i}")
          end

          message_pattern(mod).deconstruct(blk)

          mod.compile(blk, @body)
        end
      end

      def push_target(gen, mod)
        if @receiver
          message_pattern(mod).receiver.target(gen)
        else
          gen.push_scope
          gen.send(:for_method_definition, 0)
        end
      end

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
