module Atomy
  module AST
    class Branch < Block
      include NodeLike
      extend SentientNode

      children :body, :receiver, [:arguments], :block?
      attributes :name, :always_match?

      def receiver_pattern(mod)
        @recvpat = {}
        @recvpat[mod] ||=
          mod.make_pattern(@receiver)
      end

      def block_pattern(mod)
        return unless @block

        @blkpat = {}
        @blkpat[mod] ||=
          mod.make_pattern(@block)
      end

      # differences from Block:
      # - has a name
      # - doesn't check arg length or whether they match
      #   - this is handled by the main method that this is a branch of
      def create_block(g, mod)
        pos(g)

        state = g.state
        state.scope.nest_scope self

        args = make_arguments(mod)

        blk = new_generator g, @name, args

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

        # order matters quite a lot here
        args.bytecode(blk)

        recv = receiver_pattern(mod)
        if recv.binds?
          blk.push_self
          recv.deconstruct(blk, mod)
        end

        args.deconstruct_patterns(blk, mod)

        mod.compile(blk, @body)

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

      def push_branch(g, mod)
        req = []
        dfs = []
        spl = nil
        argument_patterns(mod).each do |a|
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

        g.push_cpath_top
        g.find_const :Atomy
        g.send :current_module, 0

        receiver_pattern(mod).construct(g, mod)

        req.each do |r|
          r.construct(g, mod)
        end
        g.make_array req.size

        dfs.each do |d|
          d.construct(g, mod)
        end
        g.make_array dfs.size

        if spl
          spl.construct(g, mod)
        else
          g.push_nil
        end

        if blkpat = block_pattern(mod)
          blkpat.construct(g, mod)
        else
          g.push_nil
        end

        if @always_match
          g.push_true
        else
          g.push_false
        end

        if @body.is_a?(Primitive) || @body.is_a?(Literal)
          @body.construct(g, mod)
          primitive = true
        end

        create_block(g, mod)
        g.send_with_block :new, primitive ? 8 : 7
      end
    end

    class DefineMethod < Branch
      include NodeLike
      extend SentientNode

      children :body, :receiver, [:arguments], :block?
      attributes :name, :always_match?

      alias method_name name

      def create_block(g, mod)
        super

        # set the block's module so that super works
        g.dup
        g.push_literal :@module
        receiver_pattern(mod).target(g, mod)
        g.send :instance_variable_set, 2
        g.pop
      end

      def bytecode(g, mod)
        pos(g)

        g.push_cpath_top
        g.find_const :Atomy
        receiver_pattern(mod).target(g, mod)
        g.push_literal @name
        push_branch(g, mod)
        g.push_scope
        g.send :define_branch, 4
      end
    end

    class DefineFunction < Branch
      include NodeLike
      extend SentientNode

      children :body, [:arguments], :block?
      attributes :name, :always_match?, :set?

      def receiver_pattern(mod)
        Patterns::Any.new
      end

      def bytecode(g, mod)
        pos(g)

        var = Atomy.assign_local(g, :"#@name:function", @set)
        g.push_rubinius
        g.find_const :BlockEnvironment
        g.send :new, 0

        g.push_variables

        g.push_cpath_top
        g.find_const :Atomy
        g.push_scope
        g.push_literal @name
        push_branch(g, mod)
        g.send :add_branch, 3
        g.send :build, 0

        g.send :under_context, 2
        var.set_bytecode(g)
      end
    end
  end
end
