module Atomy
  module Code
    class Block
      def initialize(body, args)
        @body = body
        @arguments = args
      end

      def bytecode(gen, mod)
        blk = build_block(gen, mod)

        gen.create_block(blk)

        gen.push_cpath_top
        gen.find_const :Proc
        gen.swap
        gen.send(:__from_block__, 1)
        gen.dup
        gen.send(:lambda_style!, 0)
        gen.pop
      end

      private

      def build_block(gen, mod)
        Atomy::Compiler.generate(mod.file) do |blk|
          # close over the outer scope
          blk.state.scope.parent = gen.state.scope

          # for now, only allow a fixed set of arguments
          blk.required_args = blk.total_args = @arguments.size

          # this bubbles up to Proc#arity and BlockEnvironment, though it
          # doesn't appear to change actual behavior of the block
          blk.arity = @arguments.size

          # create a local for each argument name
          @arguments.each do |a|
            blk.state.scope.new_local(a.text)
          end

          # build the block's body
          mod.compile(blk, @body)
        end
      end
    end
  end
end
