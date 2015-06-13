module Atomy
  module Code
    class Block
      def initialize(body, args = [], proc_argument = nil, lambda_style = true)
        @body = body

        @arguments = args.dup
        if args.last.is_a?(Atomy::Grammar::AST::Prefix) && args.last.operator == :*
          @splat_argument = @arguments.pop
        end

        @proc_argument = proc_argument

        @lambda_style = lambda_style
      end

      def bytecode(gen, mod)
        blk = build_block(gen.state.scope, mod)

        if @lambda_style
          gen.push_cpath_top
          gen.find_const :Proc
        end

        gen.create_block(blk)

        if @lambda_style
          gen.send(:__from_block__, 1)
          gen.dup
          gen.send(:lambda_style!, 0)
          gen.pop
        end
      end

      private

      def build_block(scope, mod)
        Atomy::Compiler.generate(mod.file) do |blk|
          # close over the outer scope
          blk.state.scope.parent = scope

          # for now, only allow a fixed set of arguments
          blk.required_args = blk.total_args = @arguments.size

          # discard extra arguments
          blk.splat_index = @arguments.size

          # this bubbles up to Proc#arity and BlockEnvironment, though it
          # doesn't appear to change actual behavior of the block
          if @splat_argument
            # this is + 1 so that if there are no args the arity is -1, not -0
            # (which is not a thing)
            blk.arity = -(@arguments.size + 1)
          else
            blk.arity = @arguments.size
          end

          # create a local for each argument name
          @arguments.each.with_index do |a, i|
            blk.state.scope.new_local(:"arg:#{i}")
          end

          # local for discarded splat args
          blk.state.scope.new_local(:"arg:extra")

          # pattern-match all args
          @arguments.each.with_index do |a, i|
            Assign.new(a, Variable.new(:"arg:#{i}")).bytecode(blk, mod)
          end

          # pattern-match the splat arg
          if @splat_argument
            Assign.new(@splat_argument, Variable.new(:"arg:extra")).bytecode(blk, mod)
          end

          # pattern-match the proc arg
          if @proc_argument
            Assign.new(@proc_argument, PushProc.new).bytecode(blk, mod)
          end

          # build the block's body
          mod.compile(blk, @body)
        end
      end

      class PushProc
        def initialize
        end

        def bytecode(gen, mod)
          gen.push_proc
        end
      end
    end
  end
end
