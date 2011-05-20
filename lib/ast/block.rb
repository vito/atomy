module Atomy
  module AST
    class Block < Rubinius::AST::Iter
      include NodeLike
      extend SentientNode

      children [:contents], [:arguments]
      generate

      def block_arguments
        BlockArguments.new @arguments
      end

      def block_body
        BlockBody.new @line, @contents
      end

      def body
        InlinedBody.new @line, @contents
      end

      alias :caller :body

      def bytecode(g)
        pos(g)

        state = g.state
        state.scope.nest_scope self

        blk = new_block_generator g, block_arguments

        blk.push_state self
        blk.state.push_super state.super
        blk.state.push_eval state.eval

        blk.state.push_name blk.name

        # Push line info down.
        pos(blk)

        block_arguments.bytecode(blk)

        blk.state.push_block
        blk.push_modifiers
        blk.break = nil
        blk.next = nil
        blk.redo = blk.new_label
        blk.redo.set!

        block_body.compile(blk)

        blk.pop_modifiers
        blk.state.pop_block
        blk.ret
        blk.close
        blk.pop_state

        blk.splat_index = block_arguments.splat_index
        blk.local_count = local_count
        blk.local_names = local_names

        g.create_block blk

        g.push_cpath_top
        g.find_const :Proc
        g.swap
        g.send :__from_block__, 1
      end

      def as_message(send)
        case send.receiver
        when Send
          if send.receiver.method_name == "[]"
            dup.tap do |b|
              b.arguments = send.receiver.arguments
            end.as_message(send.receiver)
          else
            send.receiver.dup.tap do |s|
              s.block = self
            end
          end
        when Variable, Unquote,
             Constant, ScopedConstant, ToplevelConstant
          send.receiver = send.receiver.to_send
          as_message(send)
        when List
          dup.tap do |b|
            b.arguments = send.receiver.elements
          end
        else
          unless send.method_name
            raise "unknown receiver for block: #{send.receiver.inspect}"
          end
        end
      end
    end

    class InlinedBody < Node
      children [:expressions]
      generate

      attr_accessor :parent

      def variables
        @variables ||= {}
      end

      def local_count
        @parent.local_names
      end

      def local_names
        @parent.local_names
      end

      def allocate_slot
        @parent.allocate_slot
      end

      def nest_scope(scope)
        scope.parent = self
      end

      def module?
        @parent.module?
      end

      def search_local(name)
        if variable = variables[name]
          variable.nested_reference
        else
          @parent.search_local(name)
        end
      end

      def pseudo_local(name)
        if variable = variables[name]
          variable.nested_reference
        elsif reference = @parent.search_local(name)
          reference.depth += 1
          reference
        end
      end

      def new_local(name)
        variables[name] =
          @parent.new_local(name + ":" + @parent.allocate_slot.to_s)
      end

      def new_nested_local(name)
        @parent.new_local(name).nested_reference
      end

      def empty?
        @expressions.empty?
      end

      def setup(g)
        g.state.scope.nest_scope self

        blk = g.state.block?
        ens = g.state.ensure?
        res = g.state.rescue?
        lop = g.state.loop?
        msn = g.state.masgn?

        g.push_state self

        g.state.push_block if blk
        g.state.push_ensure if ens
        g.state.push_rescue(res) if res
        g.state.push_loop if lop
        g.state.push_masgn if msn
      end

      def reset(g)
        g.pop_state
      end

      def bytecode(g)
        pos(g)

        setup(g)

        g.push_nil if empty?

        @expressions.each_with_index do |node,idx|
          g.pop unless idx == 0
          node.compile(g)
        end

        reset(g)
      end
    end

    class BlockArguments
      attr_reader :arguments

      def initialize(args)
        @arguments = args.collect(&:to_pattern)
      end

      def bytecode(g)
        return if @arguments.empty?

        if @arguments.last.kind_of?(Patterns::BlockPass)
          g.push_block_arg
          @arguments.pop.deconstruct(g)
        end

        g.cast_for_splat_block_arg
        @arguments.each do |a|
          if a.kind_of?(Patterns::Splat)
            a.pattern.deconstruct(g)
            return
          else
            g.shift_array
            a.match(g)
          end
        end
        g.pop
      end

      def local_names
        @arguments.collect { |a| a.local_names }.flatten
      end

      def size
        @arguments.size
      end

      def locals
        local_names.size
      end

      def required_args
        size
      end

      def total_args
        size
      end

      def splat_index
        @arguments.each do |a,i|
          return i if a.kind_of?(Patterns::Splat)
        end
        nil
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
