module Atomo
  module AST
    class Block < Rubinius::AST::Iter
      Atomo::Parser.register self

      attr_accessor :parent

      def self.rule_name
        "block"
      end

      def initialize(body, args)
        @body = BlockBody.new body
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
    end

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
        else
          g.cast_for_multi_block_arg
          @arguments.each do |a|
            g.shift_array
            a.match(g)
          end
          g.pop
        end
      end

      def local_names
        @arguments.collect { |a| a.locals }.flatten
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
        nil
      end
    end

    class BlockBody < Node
      attr_reader :expressions

      def initialize(body)
        @body = body
        @line = 1 # TODO
      end

      def empty?
        @body.empty?
      end

      def bytecode(g)
        pos(g)
        @body.each_with_index do |node,idx|
          g.pop unless idx == 0
          node.bytecode(g)
        end
      end

      def empty?
        @body.size == 0
      end
    end
  end
end
