require "delegate"

module Atomy
  module AST
    class FormalArguments < Rubinius::AST::FormalArguments19
      def initialize(line, required, optional, splat, post, block, patterns)
        if optional
          defaults = Rubinius::AST::Block.new(
            line,
            optional.collect { |n|
              Rubinius::AST::LocalVariableAssignment.new(
                line,
                n,
                Primitive.new(0, :undefined))
            })
        end

        super(line, required, defaults, splat, post, block)

        @patterns = patterns
      end

      def set_patterns(g)
        @patterns.each do |n, p|
          g.state.scope.search_local(n).get_bytecode(g)
          p.match(g)
        end
      end

      def deconstruct_patterns(g)
        @patterns.each do |n, p|
          if p.binds?
            g.state.scope.search_local(n).get_bytecode(g)
            p.deconstruct(g)
          end
        end
      end
    end

    class Block < Rubinius::AST::Iter
      include NodeLike
      extend SentientNode

      children [:contents], [:arguments], :block?
      generate

      def body
        BlockBody.new @line, @contents
      end

      alias :caller :body

      def implicit_arguments
        []
      end

      def implicit_patterns
        []
      end

      def make_arguments
        required = implicit_arguments
        optional = nil
        post = nil
        splat = nil
        block = nil

        patterns = implicit_patterns

        @arguments.collect(&:to_pattern).each.with_index do |p, i|
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
          patterns << [block, @block.to_pattern]
        end

        FormalArguments.new(@line, required, optional, splat, post, block, patterns)
      end

      def create_block(g)
        pos(g)

        state = g.state
        state.scope.nest_scope self

        args = make_arguments

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

        args.set_patterns(blk)

        body.compile(blk)

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
        g.dup
        g.send :lambda_style!, 0
        g.pop
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
