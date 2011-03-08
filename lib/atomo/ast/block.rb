module Atomo
  module AST
    class Block < Rubinius::AST::Iter
      include NodeLike

      attr_accessor :parent

      def initialize(line, body, args)
        @line = line

        if body.kind_of? BlockBody
          @body = body
        else
          @body = BlockBody.new @line, body
        end

        if args.kind_of? BlockArguments
          @arguments = args
        else
          @arguments = BlockArguments.new args
        end

        @parent = nil
      end

      def construct(g, d)
        get(g)
        g.push_int @line
        @body.construct(g, d)
        @arguments.construct(g, d)
        g.send :new, 3
      end

      attr_reader :body, :arguments

      def recursively(stop = nil, &f)
        return f.call self if stop and stop.call(self)
        f.call Block.new(@line, body.recursively(stop, &f), @arguments)
      end
    end

    class BlockArguments < AST::Node
      attr_reader :arguments

      def initialize(args)
        @arguments = args.collect do |a|
          if a.kind_of?(Patterns::Pattern)
            a
          else
            Patterns.from_node a
          end
        end
      end

      def construct(g, d = nil)
        get(g)
        @arguments.each do |a|
          a.construct(g)
        end
        g.make_array @arguments.size
        g.send :new, 1
      end

      def bytecode(g)
        return if @arguments.empty?

        if @arguments.last.kind_of?(Patterns::BlockPass)
          g.push_block_arg
          @arguments.pop.deconstruct(g)
        end

        g.cast_for_splat_block_arg
        @arguments.each do |a|
          if a.kind_of?(Patterns::Splat)
            a.pattern.deconstruct(g)
            return
          else
            g.shift_array
            a.match(g)
          end
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
        size
      end

      def total_args
        size
      end

      def splat_index
        @arguments.each do |a,i|
          return i if a.kind_of?(Patterns::Splat)
        end
        nil
      end
    end

    class BlockBody < Node
      attr_reader :expressions

      def initialize(line, expressions)
        @expressions = expressions
        @line = line
      end

      def construct(g, d = nil)
        get(g)
        g.push_int @line
        @expressions.each do |e|
          e.construct(g, d)
        end
        g.make_array @expressions.size
        g.send :new, 2
      end

      def empty?
        @expressions.empty?
      end

      def recursively(stop, &f)
        BlockBody.new(@line, @expressions.collect { |n| n.recursively(stop, &f) })
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
