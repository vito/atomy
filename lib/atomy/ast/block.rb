require "delegate"

module Atomy
  module AST
    class FormalArguments < Rubinius::AST::FormalArguments19
      def initialize(line, required, optional, splat, post, block, patterns)
        defaults = optional && Rubinius::AST::Block.new(
          line,
          optional.collect do |n, d|
            Rubinius::AST::LocalVariableAssignment.new(
              line,
              n,
              CompileWrapper.new(d)
            )
          end
        )

        super(line, required, defaults, splat, post, block)

        @patterns = patterns
      end

      def set_patterns(g)
        @patterns.each do |n, p|
          g.state.scope.search_local(n).get_bytecode(g)
          p.match(g)
        end
      end

      class CompileWrapper < SimpleDelegator
        def bytecode(g)
          __getobj__.compile(g)
        end
      end
    end

    class Block < Rubinius::AST::Iter
      include NodeLike
      extend SentientNode

      children [:contents], [:arguments], :block?
      attributes :name?
      generate

      def body
        BlockBody.new @line, @contents
      end

      alias :caller :body

      def make_arguments
        required = []
        optional = nil
        post = nil
        splat = nil
        block = nil

        locals = []

        @arguments.collect(&:to_pattern).each.with_index do |p, i|
          name = :"@arg:#{i + 1}"
          locals << [name, p]

          if p.is_a?(Patterns::Splat)
            splat = name
          elsif p.is_a?(Patterns::Default)
            optional ||= []
            optional << [name, p.default]
          elsif splat
            post ||= []
            post << name
          else
            required << name
          end
        end

        if @block
          block = :@block
          locals << [block, @block.to_pattern]
        end

        FormalArguments.new(@line, required, optional, splat, post, block, locals)
      end

      def create_block(g)
        pos(g)

        state = g.state
        state.scope.nest_scope self

        args = make_arguments

        blk = new_block_generator g, args
        blk.name = @name if @name

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

        too_few = blk.new_label
        done = blk.new_label

        blk.passed_arg(args.required_args - 1)
        blk.gif too_few

        args.bytecode(blk)

        args.set_patterns(blk)

        body.compile(blk)

        blk.goto done

        too_few.set!
        blk.push_self
        blk.push_cpath_top
        blk.find_const :ArgumentError
        blk.push_literal "block given too few arguments"
        blk.send :new, 1
        blk.send :raise, 1, true

        done.set!

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

      def bytecode(g)
        create_block g

        g.push_cpath_top
        g.find_const :Proc
        g.swap
        g.send :__from_block__, 1
      end
    end

    class BlockBody < Node
      children [:expressions]
      generate

      def empty?
        @expressions.empty?
      end

      def bytecode(g)
        pos(g)

        g.push_nil if empty?

        @expressions.each_with_index do |node,idx|
          g.pop unless idx == 0
          node.compile(g)
        end
      end
    end
  end
end
