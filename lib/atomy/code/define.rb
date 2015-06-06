module Atomy
  module Code
    class Define
      def initialize(name, body, arguments = [], receiver = nil, block = nil)
        @name = name
        @body = body
        @receiver = receiver
        @arguments = arguments
        @block = block
      end

      private

      def push_branch(gen, mod)
        gen.push_cpath_top
        gen.find_const(:Atomy)
        gen.find_const(:Method)
        gen.find_const(:Branch)

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

        if @block
          block_pattern = mod.pattern(@block)
          branch_locals += block_pattern.locals
          mod.compile(gen, block_pattern)
        else
          gen.push_nil
        end

        branch_locals.each do |loc|
          gen.push_literal(loc)
        end
        gen.make_array(branch_locals.size)

        gen.create_block(build_branch_body(gen.state.scope, mod, branch_locals))

        gen.send_with_block(:new, 4)
      end

      def build_branch_body(scope, mod, locals)
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
