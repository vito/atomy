module Atomy
  module Code
    class Define
      def initialize(name, body = nil, receiver = nil, arguments = [],
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

        if @receiver
          mod.compile(gen, receiver_pattern(mod))
        else
          gen.push_nil
        end

        pre_argument_patterns(mod).each do |p|
          mod.compile(gen, p)
        end
        gen.make_array(@arguments.size)

        default_argument_patterns(mod).each do |d, p|
          mod.compile(gen, p)
        end
        gen.make_array(@default_arguments.size)

        if p = splat_argument_pattern(mod)
          mod.compile(gen, p)
        else
          gen.push_nil
        end

        post_argument_patterns(mod).each do |p|
          mod.compile(gen, p)
        end
        gen.make_array(@post_arguments.size)

        if p = proc_argument_pattern(mod)
          mod.compile(gen, p)
        else
          gen.push_nil
        end

        gen.create_block(build_block(gen.state.scope, mod, @name, @body))

        gen.send_with_block(:new, 6)
      end

      def build_block(scope, mod, name, body)
        Atomy::Compiler.generate(mod.file) do |blk|
          # set method name so calls to super work
          blk.name = name

          # close over the outer scope
          blk.state.scope.parent = scope

          total_patterns = 0
          total_patterns += 1 if @receiver
          total_patterns += @arguments.size + @default_arguments.size + @post_arguments.size
          total_patterns += 1 if @splat_argument
          total_patterns += 1 if @proc_argument

          blk.total_args = total_patterns * 2
          blk.required_args = blk.total_args

          # this bubbles up to Proc#arity and BlockEnvironment, though it
          # doesn't appear to change actual behavior of the block
          blk.arity = blk.total_args

          arg = 0

          if @receiver
            blk.state.scope.new_local("arg:self:pat")
            blk.state.scope.new_local("arg:self")
          end

          @arguments.size.times do
            blk.state.scope.new_local(:"arg:#{arg}:pat")
            blk.state.scope.new_local(:"arg:#{arg}")
            arg += 1
          end

          @default_arguments.size.times do
            blk.state.scope.new_local(:"arg:#{arg}:pat")
            blk.state.scope.new_local(:"arg:#{arg}")
            arg += 1
          end

          if @splat_argument
            blk.state.scope.new_local(:"arg:splat:pat")
            blk.state.scope.new_local(:"arg:splat")
          end

          @post_arguments.size.times do
            blk.state.scope.new_local(:"arg:#{arg}:pat")
            blk.state.scope.new_local(:"arg:#{arg}")
            arg += 1
          end

          if @proc_argument
            blk.state.scope.new_local(:"arg:proc:pat")
            blk.state.scope.new_local(:"arg:proc")
          end

          loc = 0
          if p = receiver_pattern(mod)
            blk.push_local(loc)
            blk.push_local(loc+1)
            p.assign(blk)
            blk.pop_many(2)

            loc += 2
          end

          pre_argument_patterns(mod).each do |p|
            blk.push_local(loc)
            blk.push_local(loc+1)
            p.assign(blk)
            blk.pop_many(2)

            loc += 2
          end

          default_argument_patterns(mod).each do |d, p|
            assign = blk.new_label

            # [pat]
            blk.push_local(loc)

            # [val, pat]
            blk.push_local(loc+1)

            # [val, val, pat]
            blk.dup

            # [val, pat]
            blk.goto_if_not_undefined(assign)

            # [pat]
            blk.pop

            # [val, pat]
            mod.compile(blk, d.default)

            assign.set!

            # [val, pat]
            p.assign(blk)

            # []
            blk.pop_many(2)

            loc += 2
          end

          if p = splat_argument_pattern(mod)
            blk.push_local(loc)
            blk.push_local(loc+1)
            p.assign(blk)
            blk.pop_many(2)

            loc += 2
          end

          post_argument_patterns(mod).each do |p|
            blk.push_local(loc)
            blk.push_local(loc+1)
            p.assign(blk)
            blk.pop_many(2)

            loc += 2
          end

          if p = proc_argument_pattern(mod)
            blk.push_local(loc)
            blk.push_local(loc+1)
            p.assign(blk)
            blk.pop_many(2)

            loc += 2
          end

          # build the method branch's body
          mod.compile(blk, body)
        end
      end

      def receiver_pattern(mod)
        return unless @receiver

        @receiver_pattern ||= mod.pattern(@receiver)
      end

      def pre_argument_patterns(mod)
        @pre_argument_patterns ||=
          @arguments.collect do |a|
            mod.pattern(a)
          end
      end

      def default_argument_patterns(mod)
        @default_argument_patterns ||=
          @default_arguments.collect do |d|
            [d, mod.pattern(d.node)]
          end
      end

      def post_argument_patterns(mod)
        @post_argument_patterns ||=
          @post_arguments.collect do |a|
            mod.pattern(a)
          end
      end

      def splat_argument_pattern(mod)
        return unless @splat_argument

        @splat_argument_pattern ||= mod.pattern(@splat_argument)
      end

      def proc_argument_pattern(mod)
        return unless @proc_argument

        @proc_argument_pattern ||= mod.pattern(@proc_argument)
      end
    end
  end
end
