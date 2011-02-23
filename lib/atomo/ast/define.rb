module Atomo
  module AST
    class Define < Rubinius::AST::ClosedScope
      def initialize(name, recv, args, body)
        @name = name
        @receiver = recv
        @arguments = DefineArguments.new(args)
        @body = body
        @line = 1 # TODO
      end

      def compile_body(g)
        meth = new_generator(g, "__atomo_#{@name}__".to_sym, @arguments)
        meth.push_state self
        meth.state.push_super self
        meth.definition_line @line
        meth.state.push_name @name
        @arguments.bytecode(meth)
        meth.push_self
        @receiver.deconstruct(meth)
        @body.bytecode(meth)
        meth.state.pop_name
        meth.local_count = local_count
        meth.local_names = local_names
        meth.ret
        meth.close
        meth.pop_state
        meth
      end

      def bytecode(g)
        pos(g)

        g.push_const :Atomo
        @receiver.target(g)
        g.push_literal @name.to_sym

        create = g.new_label
        added = g.new_label
        @receiver.construct(g)
        @arguments.patterns.each do |p|
            p.construct(g)
        end
        g.make_array @arguments.size
        g.make_array 2
        g.push_unique_literal @body.method(:bytecode)
        g.make_array 2

        @receiver.target(g)
        g.push_literal "@__atomo_#{@name}__".to_sym
        g.send :instance_variable_get, 1
        g.dup
        g.gif create

        g.swap
        g.send :<<, 1
        g.goto added

        create.set!
        g.pop
        g.make_array 1
        @receiver.target(g)
        g.swap
        g.push_literal "@__atomo_#{@name}__".to_sym
        g.swap
        g.send :instance_variable_set, 2

        added.set!

        g.send :add_method, 3
      end

      def local_count
        local_names.size
      end

      def local_names
        @receiver.local_names + @arguments.local_names
      end

      class DefineArguments
        attr_accessor :patterns

        def initialize(args)
          @patterns = args.collect { |a| Patterns.from_node(a) }
        end

        def bytecode(g)
          return if @patterns.empty?
          g.cast_for_multi_block_arg
          @patterns.each do |a|
            g.shift_array
            a.deconstruct(g)
          end
          g.pop
        end

        def local_names
          @patterns.collect { |a| a.local_names }.flatten
        end

        def size
          @patterns.size
        end

        def locals
          local_names.size
        end

        def required_args
          size # TODO
        end

        def total_args
          size # TODO
        end

        def splat_index
          nil
        end
      end
    end
  end
end