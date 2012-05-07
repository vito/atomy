require "delegate"

module Atomy
  module AST
    class Block < Rubinius::AST::Iter
      include NodeLike
      extend SentientNode

      children [:contents], [:arguments], :block?

      class Arguments < Rubinius::AST::FormalArguments19
        class Default < Rubinius::AST::Node
          def initialize(line)
            @line = line
          end

          def bytecode(g)
            pos(g)
            g.push_undef
          end
        end

        def initialize(line, required, optional, splat, post, block, patterns)
          if optional
            defaults = Rubinius::AST::Block.new(
              line,
              optional.collect { |n|
                Rubinius::AST::LocalVariableAssignment.new(
                  line,
                  n,
                  Default.new(0))
              })
          end

          super(line, required, defaults, splat, post, block)

          @patterns = patterns
        end

        def set_patterns(g, mod)
          @patterns.each do |n, p|
            g.state.scope.search_local(n).get_bytecode(g)
            p.match(g, mod)
          end
        end

        def deconstruct_patterns(g, mod)
          @patterns.each do |n, p|
            if p.binds?
              g.state.scope.search_local(n).get_bytecode(g)
              p.deconstruct(g, mod)
            end
          end
        end
      end

      class Body < Node
        children [:expressions]

        def empty?
          @expressions.empty?
        end

        def bytecode(g, mod)
          pos(g)

          g.push_nil if empty?

          @expressions.each_with_index do |node,idx|
            g.pop unless idx == 0
            mod.compile(g, node)
          end
        end
      end

      def body
        Body.new @line, @contents
      end

      alias :caller :body

      def argument_patterns(mod)
        @argpats = {}
        @argpats[mod] ||=
          @arguments.collect { |a|
            mod.make_pattern(a)
          }
      end

      def make_arguments(mod)
        return @args[mod] if @args && @args[mod]

        required = []
        optional = nil
        post = nil
        splat = nil
        block = nil

        patterns = []

        argument_patterns(mod).each.with_index do |p, i|
          name = :"@arg:#{i + 1}"
          patterns << [name, p]

          if p.is_a?(Patterns::Splat)
            splat = name
          elsif p.is_a?(Patterns::Default)
            optional ||= []
            optional << name
          elsif splat || optional
            post ||= []
            post << name
          else
            required << name
          end
        end

        if @block
          block = :@block
          patterns << [block, mod.make_pattern(@block)]
        end

        @args ||= {}
        @args[mod] =
          Arguments.new(
            @line, required, optional, splat, post, block, patterns)
      end

      def create_block(g, mod)
        pos(g)

        state = g.state
        state.scope.nest_scope self

        args = make_arguments(mod)

        blk = new_block_generator g, args

        blk.push_state self

        blk.state.push_super state.super
        blk.state.push_eval state.eval

        blk.definition_line(@line)

        blk.state.push_name blk.name

        pos(blk)

        blk.state.push_block
        blk.push_modifiers
        blk.break = nil
        blk.next = nil
        blk.redo = blk.new_label
        blk.redo.set!

        args.bytecode(blk)

        args.set_patterns(blk, mod)

        mod.compile(blk, body)

        blk.pop_modifiers
        blk.state.pop_block

        blk.ret
        blk.close
        blk.pop_state

        blk.splat_index = args.splat_index
        blk.local_count = local_count
        blk.local_names = local_names

        g.create_block blk
      end

      def bytecode(g, mod)
        create_block(g, mod)

        g.push_cpath_top
        g.find_const :Proc
        g.swap
        g.send :__from_block__, 1
        g.dup
        g.send :lambda_style!, 0
        g.pop
      end
    end
  end
end
