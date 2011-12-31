module Atomy
  module AST
    class Define < Node
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
        Block.new(
          @line,
          [@body],
          [@receiver, Word.new(0, :arguments)] + @arguments,
          @block,
          @method_name
        ).create_block(g)

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
