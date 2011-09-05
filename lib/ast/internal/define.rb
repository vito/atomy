module Atomy
  module AST
    class Define < Node
      children :pattern, :body
      generate

      def arguments
        return @arguments if @arguments

        case @pattern
        when Binary
          args = [@pattern.rhs]
        when Variable, Unary
          args = []
        when Call
          args = @pattern.arguments
        when Compose
          case @pattern.right
          when Call
            args = @pattern.right.arguments
          when Variable
            args = []
          when List
            args = @pattern.right.elements
          end
        end

        raise "unknown pattern #{@pattern.inspect}" unless args

        @arguments = args.collect(&:to_pattern)
      end

      def receiver
        return @receiver if @receiver

        case @pattern
        when Binary
          recv = @pattern.lhs
        when Call, Variable
          recv = Primitive.new(@pattern.line, :self)
        when Compose
          recv = @pattern.left
        end

        raise "unknown pattern #{@pattern.inspect}" unless recv

        @receiver = recv.to_pattern
      end

      def message_name
        return @message_name if @message_name

        case @pattern
        when Variable
          name = @pattern.name
        when Call
          name = @pattern.name.name
        when Compose
          case @pattern.right
          when Variable
            name = @pattern.right.name
          when Call
            name = @pattern.right.name.name
          when List
            name = "[]"
          end
        else
          name = @pattern.message_name
        end

        (@message_name = name) || raise "unknown pattern #{@pattern.inspect}"
      end

      def prepare_all
        dup.tap do |x|
          x.body = x.body.prepare_all
        end
      end

      def bytecode(g)
        pos(g)

        defn = receiver.kind_of?(Patterns::Match) && receiver.value == :self

        g.push_cpath_top
        g.find_const :Atomy
        receiver.target(g)
        g.push_literal message_name
        g.send :to_sym, 0

        create = g.new_label
        added = g.new_label
        receiver.construct(g)
        arguments.each do |p|
          p.construct(g)
        end
        g.make_array arguments.size
        g.make_array 2
        @body.prepare_all.construct(g)
        g.push_cpath_top
        g.find_const :Thread
        g.send :current, 0
        g.push_literal :atomy_provide_in
        g.send :[], 1
        g.make_array 3

        receiver.target(g)
        g.push_literal "@atomy::"
        g.push_literal message_name
        g.string_build 2
        g.send :to_sym, 0
        g.send :instance_variable_get, 1
        g.dup
        g.gif create

        g.push_cpath_top
        g.find_const :Atomy
        g.move_down 2
        g.send :insert_method, 2
        g.goto added

        create.set!
        g.pop
        g.make_array 1
        receiver.target(g)
        g.swap
        g.push_literal "@atomy::"
        g.push_literal message_name
        g.string_build 2
        g.send :to_sym, 0
        g.swap
        g.send :instance_variable_set, 2

        added.set!

        g.push_scope
        g.push_literal :public
        g.push_scope
        g.send :active_path, 0
        g.push_int @line
        g.push_literal defn
        g.send :add_method, 8
      end

      def local_count
        local_names.size
      end

      def local_names
        arguments.inject(receiver.local_names) do |acc, a|
          acc + a.local_names
        end
      end
    end
  end
end
