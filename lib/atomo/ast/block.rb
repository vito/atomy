module Atomo
  module AST
    class Block < Rubinius::AST::Iter
      Atomo::Parser.register self

      attr_accessor :parent

      def self.rule_name
        "block"
      end

      def initialize(body, args)
        if body.kind_of? BlockBody
          @body = body
        else
          @body = BlockBody.new body
        end

        if args.kind_of? BlockArguments
          @arguments = args
        else
          @arguments = BlockArguments.new args
        end

        @parent = nil
        @line = 1 # TODO
      end

      attr_reader :body, :arguments

      def self.grammar(g)
        args =
          g.seq(g.t(g.many(g.seq(:sp, g.t(:level1)))), :sp, "|")

        g.block =
          g.seq(
            '{', g.t(g.maybe(args)), :sp,
            g.t(:some_expressions), :sp, '}'
          ) do |args,v|
            Block.new(v, Array(args))
          end
      end

      def recursively(&f)
        f.call Block.new(body.recursively(&f), @arguments)
      end

      def construct(g, d)
        get(g)
        @body.expressions.each do |e|
          e.construct(g, d)
        end
        g.make_array @body.expressions.size
        g.push_literal @arguments
        g.send :new, 2
      end
    end

    class BlockArguments < AST::Node
      def initialize(args)
        @arguments = args.collect { |a| Patterns.from_node a }
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
            if a.kind_of?(Patterns::Variadic)
              a.pattern.deconstruct(g)
              return
            else
              g.shift_array
              a.match(g)
            end
          end
          g.pop
        end
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
          return i if a.kind_of?(Patterns::Variadic)
        end
        nil
      end
    end

    class BlockBody < Node
      attr_reader :expressions

      def initialize(expressions)
        @expressions = expressions
        @line = 1 # TODO
      end

      def empty?
        @expressions.empty?
      end

      def recursively(&f)
        BlockBody.new(@expressions.collect { |n| n.recursively(&f) })
      end

      def bytecode(g)
        pos(g)

        g.push_nil if empty?

        @expressions.each_with_index do |node,idx|
          g.pop unless idx == 0
          node.bytecode(g)
        end
      end
    end
  end
end
