module Atomy
  module AST
    class Branch < Block
      include NodeLike
      extend SentientNode

      children :body, :receiver, [:arguments], :block?
      attributes :name
      generate

      def implicit_arguments
        [:@receiver]
      end

      def implicit_patterns
        [[:@receiver, receiver_pattern]]
      end

      def argument_patterns
        @argument_patterns ||= @arguments.collect(&:to_pattern)
      end

      def receiver_pattern
        @receiver_pattern ||= @receiver.to_pattern
      end

      def block_pattern
        @block && @block.to_pattern
      end

      # differences from Block:
      # - has a name
      # - doesn't check arg length or whether they match
      #   - this is handled by the main method that this is a branch of
      def create_block(g)
        pos(g)

        state = g.state
        state.scope.nest_scope self

        args = make_arguments

        blk = new_block_generator g, args
        blk.name = @name

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

        args.deconstruct_patterns(blk)

        @body.compile(blk)

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

      def push_branch(g)
        req = []
        dfs = []
        spl = nil
        argument_patterns.each do |a|
          case a
          when Patterns::Splat
            spl = a
          when Patterns::Default
            dfs << a
          else
            req << a
          end
        end

        g.push_cpath_top
        g.find_const :Atomy
        g.find_const :Branch

        receiver_pattern.construct(g)

        req.each do |r|
          r.construct(g)
        end

        g.make_array req.size
        dfs.each do |d|
          d.construct(g)
        end

        g.make_array dfs.size
        if spl
          spl.construct(g)
        else
          g.push_nil
        end

        if block_pattern
          block_pattern.construct(g)
        else
          g.push_nil
        end

        create_block(g)

        g.send_with_block :new, 5
      end
    end

    class Define < Branch
      include NodeLike
      extend SentientNode

      children :body, :receiver, [:arguments], :block?
      attributes :name
      generate

      alias method_name name

      def create_block(g)
        super

        # set the block's module so that super works
        g.dup
        g.push_literal :@module
        receiver_pattern.target(g)
        g.send :instance_variable_set, 2
        g.pop
      end

      def bytecode(g)
        pos(g)

        g.push_cpath_top
        g.find_const :Atomy
        receiver_pattern.target(g)
        g.push_literal @name
        push_branch(g)
        g.push_scope
        g.send :define_branch, 4
      end
    end

    class Function < Branch
      include NodeLike
      extend SentientNode

      children :body, [:arguments], :block?
      attributes :name
      generate

      def receiver_pattern
        Patterns::Any.new
      end

      def bytecode(g)
        pos(g)

        var = Atomy.assign_local(g, :"#@name:function")
        g.push_rubinius
        g.find_const :BlockEnvironment
        g.send :new, 0

        g.push_variables

        g.push_cpath_top
        g.find_const :Atomy
        g.push_scope
        g.push_literal @name
        push_branch(g)
        g.send :add_branch, 3
        g.send :build, 0

        g.send :under_context, 2
        var.set_bytecode(g)
      end
    end
  end
end
