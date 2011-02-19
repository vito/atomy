module Atomo
  module AST
    class BlockArguments < AST::Node
      def initialize(args)
        @arguments = args.collect { |a| Pattern.from_node a }
      end

      def bytecode(g)
        case @arguments.size
        when 0
        when 1
          g.cast_for_single_block_arg
          @arguments[0].match(g)
          g.pop
        else
          g.cast_for_multi_block_arg
          @arguments.each do |a|
            g.shift_array
            a.match(g)
            #g.pop # remove unshifted val
          end
          g.pop # remove array
        end
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
    end

    class Block < Rubinius::AST::Iter
      Atomo::Parser.register self

      attr_accessor :parent

      def self.rule_name
        "block"
      end

      def initialize(body, args)
        @body = body
        @arguments = BlockArguments.new args
        @parent = nil
        @line = 1 # TODO
      end

      attr_reader :body, :arguments

      def self.grammar(g)
        name = g.seq(g.t(/[a-zA-Z][a-zA-Z0-9_]*/), :sp)
        args = g.seq(g.t(g.many(g.seq(:sp, g.t(:level1)))), :sp, "|")

        g.block = g.seq('{', g.t(g.maybe(args)), :sp,
                             g.t(:expressions), :sp, '}') do |args,v|
          p :as => args, :es => v
          Block.new(v, Array(args))
        end
      end

      def bytecode(g)
        pos(g)

        state = g.state
        state.scope.nest_scope self

        c = new_block_generator g, @arguments
        c.push_state(self)
        c.local_names = @arguments.local_names

        @arguments.bytecode(c)

        @body.each_with_index do |node,idx|
          c.pop unless idx == 0
          node.bytecode(c)
        end

        c.ret
        c.close

        g.create_block c
      end
    end
  end
end
