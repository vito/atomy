module Atomy
  module Code
    class Define
      def initialize(name, body, receiver = nil, arguments = [],
                     default_arguments = [], splat_argument = nil,
                     post_arguments = [], proc_argument = nil)
        @name = name
        @body = body
        @receiver = receiver
        @arguments = arguments
        @default_arguments = default_arguments
        @splat_argument = splat_argument
        @post_arguments = post_arguments
        @proc_argument = proc_argument
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

        @default_arguments.each do |d|
          pattern = mod.pattern(d.node)
          branch_locals += pattern.locals
          mod.compile(gen, pattern)
          gen.create_block(build_block(gen.state.scope, mod, branch_locals, :"#{@name}:default", d.default))
          gen.make_array(2)
        end
        gen.make_array(@default_arguments.size)

        if @splat_argument
          splat_argument_pattern = mod.pattern(@splat_argument)
          branch_locals += splat_argument_pattern.locals
          mod.compile(gen, splat_argument_pattern)
        else
          gen.push_nil
        end

        @post_arguments.each do |p|
          pattern = mod.pattern(p)
          branch_locals += pattern.locals
          mod.compile(gen, pattern)
        end
        gen.make_array(@post_arguments.size)

        if @proc_argument
          proc_argument_pattern = mod.pattern(@proc_argument)
          branch_locals += proc_argument_pattern.locals
          mod.compile(gen, proc_argument_pattern)
        else
          gen.push_nil
        end

        branch_locals.each do |loc|
          gen.push_literal(loc)
        end
        gen.make_array(branch_locals.size)

        gen.create_block(build_block(gen.state.scope, mod, branch_locals, @name, @body))

        gen.send_with_block(:new, 7)
      end

      def build_block(scope, mod, locals, name, body)
        Atomy::Compiler.generate(mod.file) do |blk|
          # set method name so calls to super work
          blk.name = name

          # close over the outer scope
          blk.state.scope.parent = scope

          # only allow a fixed set of arguments; splats and defaults are
          # resolved before this block is even called
          blk.required_args = blk.total_args = locals.size

          # this bubbles up to Proc#arity and BlockEnvironment, though it
          # doesn't appear to change actual behavior of the block
          blk.arity = locals.size

          # assign each arg to the binding from the patterns
          locals.each do |local|
            blk.state.scope.new_local(local)
          end

          # build the method branch's body
          mod.compile(blk, body)
        end
      end
    end
  end
end
