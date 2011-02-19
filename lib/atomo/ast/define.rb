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
        meth = new_generator(g, @name.to_sym, @arguments)
        meth.push_state self
        meth.state.push_super self
        meth.definition_line @line
        meth.state.push_name @name
        @arguments.bytecode(meth)
        meth.push_self
        @receiver.match(meth)
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

        g.push_rubinius
        g.push_literal @name.to_sym
        g.push_generator compile_body(g)
        @receiver.target(g)
        g.push_nil
        g.send :add_method, 4

        g.push :nil
      end

      def local_count
        local_names.size
      end

      def local_names
        @receiver.locals + @arguments.local_names
      end

      class DefineArguments
        def initialize(args)
          @arguments = args.collect { |a| Pattern.from_node(a) }
        end

        def bytecode(g)
          g.cast_for_multi_block_arg
          @arguments.each do |a|
            g.shift_array
            a.match(g)
            #g.pop # remove unshifted val
          end
          g.pop # remove array
          # @arguments.each do |a|
            # g.send :inspect, 0
            # g.send :display, 0
            # g.pop
            # a.match(g)
          # end
        end

        def local_names
          @arguments.collect { |a| a.locals }.flatten
        end

        def size
          @arguments.size
        end

        def locals
          @arguments.size # TODO
        end

        def required_args
          @arguments.size # TODO
        end

        def total_args
          @arguments.size # TODO
        end

        def splat_index
          nil
        end
      end
    end
  end
end