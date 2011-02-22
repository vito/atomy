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
        @receiver.match(meth, true)
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

        create = g.new_label
        added = g.new_label

        @receiver.target(g)
        g.dup
        g.push_literal "@__atomo_#{@name}__".to_sym
        g.send :instance_variable_defined?, 1
        g.gif create

        g.push_literal "@__atomo_#{@name}__".to_sym
        g.send :instance_variable_get, 1
        g.dup
        g.send :size, 0
        g.send :to_s, 0

        g.push_literal "#{@name}:"
        g.swap
        g.send :+, 1
        g.push_literal ":"
        g.send :+, 1
        @receiver.target(g)
        g.send :name, 0
        g.send :+, 1
        g.send :to_sym, 0
        g.dup

        @receiver.construct(g)
        g.swap
        g.make_array 2

        @receiver.target(g)
        g.push_literal "@__atomo_#{@name}__".to_sym
        g.send :instance_variable_get, 1
        g.swap
        g.send :<<, 1
        g.pop
        g.goto added

        create.set!
        g.push_literal "#{@name}:0:"
        @receiver.target(g)
        g.send :name, 0
        g.send :+, 1
        g.send :to_sym, 0
        g.dup
        @receiver.construct(g)
        g.swap
        g.make_array 2
        g.make_array 1
        @receiver.target(g)
        g.swap
        g.push_literal "@__atomo_#{@name}__".to_sym
        g.swap
        g.send :instance_variable_set, 2
        g.pop

        added.set!

        g.push_rubinius
        g.swap
        g.push_generator compile_body(g)
        @receiver.target(g)
        g.push_nil
        g.send :add_method, 4
        g.pop

        @receiver.target(g)
        g.dup
        g.push_literal "@__atomo_#{@name}__".to_sym
        g.send :instance_variable_get, 1

        g.push_literal @name.to_sym
        g.swap
        g.push_const :Atomo
        g.move_down 3
        g.send :add_method, 3
      end

      def local_count
        local_names.size
      end

      def local_names
        @receiver.local_names + @arguments.local_names
      end

      class DefineArguments
        def initialize(args)
          @arguments = args.collect { |a| Patterns.from_node(a) }
        end

        def bytecode(g)
          return if @arguments.empty?
          g.cast_for_multi_block_arg
          @arguments.each do |a|
            g.shift_array
            a.match(g)
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