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

        branch_locals = []

        if @receiver
          receiver_pattern = mod.pattern(@receiver)
          branch_locals += receiver_pattern.locals
          mod.compile(gen, receiver_pattern)
        else
          gen.push_nil
        end

        @arguments.each do |a|
          pattern = mod.pattern(a)
          branch_locals += pattern.locals
          mod.compile(gen, pattern)
        end

        gen.make_array(@arguments.size)

        gen.send(:new, 2)

        gen.create_block(build_branch(gen.state.scope, mod, branch_locals))

        gen.send_with_block(:define_branch, 3)
      end

      private

      def build_branch(scope, mod, locals)
        Atomy::Compiler.generate(mod.file) do |blk|
          # close over the outer scope
          blk.state.scope.parent = scope

          # only allow a fixed set of arguments; splats should be resolved
          # upstream once they're implemented
          blk.required_args = blk.total_args = locals.size

          # this bubbles up to Proc#arity and BlockEnvironment, though it
          # doesn't appear to change actual behavior of the block
          blk.arity = locals.size

          # assign each arg to the binding from the patterns
          locals.each do |local|
            blk.state.scope.new_local(local)
          end

          # build the method branch's body
          mod.compile(blk, @body)
        end
      end
    end
  end
end
