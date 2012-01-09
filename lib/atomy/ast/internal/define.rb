module Atomy
  module AST
    class Define < Node
      class Method < Block
        include NodeLike
        extend SentientNode

        children :receiver, [:contents], [:arguments], :block?
        attributes :name
        generate

        def make_arguments
          required = [:@receiver, :arguments]
          optional = nil
          post = nil
          splat = nil
          block = nil

          patterns = [[:@receiver, @receiver.to_pattern]]

          @arguments.collect(&:to_pattern).each.with_index do |p, i|
            name = :"@arg:#{i + 1}"
            patterns << [name, p]

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
      end

      children :body, :receiver, [:arguments], :block?
      attributes :method_name, [:defn, "false"]
      generate

      def argument_patterns
        @argument_patterns ||= @arguments.collect(&:to_pattern)
      end

      def receiver_pattern
        @receiver_pattern ||= @receiver.to_pattern
      end

      def block_pattern
        @block && @block.to_pattern
      end

      def compile_body(g)
        Method.new(
          @line,
          @receiver,
          [@body],
          @arguments,
          @method_name,
          @block).create_block(g)

        # set the block's module so that super works
        g.dup
        g.push_literal :@module

        if @defn
          g.push_self
        else
          receiver_pattern.target(g)
        end

        g.send :instance_variable_set, 2
        g.pop
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

        compile_body(g)

        g.send_with_block :new, 5
      end

      def bytecode(g)
        pos(g)

        g.push_cpath_top
        g.find_const :Atomy
        if @defn
          g.push_self
        else
          receiver_pattern.target(g)
        end
        g.push_literal @method_name

        push_branch(g)

        if @defn
          g.push_variables
          g.send :method_visibility, 0
        else
          g.push_literal :public
        end
        g.push_scope
        g.push_literal @defn
        g.send :define_branch, 6
      end

      def local_count
        local_names.size
      end

      def local_names
        argument_patterns.inject(receiver_pattern.local_names) do |acc, a|
          acc + a.local_names
        end
      end
    end
  end
end
