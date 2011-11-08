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
        when Word, Unary
          args = []
        when Call
          args = @pattern.arguments
        when Compose
          case @pattern.right
          when Call
            args = @pattern.right.arguments
          when Word
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
        when Unary
          recv = @pattern.receiver
        when Call, Word
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
        when Word
          name = @pattern.text
        when Call
          name = @pattern.name.text
        when Compose
          case @pattern.right
          when Word
            name = @pattern.right.text
          when Call
            name = @pattern.right.name.text
          when List
            name = "[]"
          end
        else
          name = @pattern.message_name
        end

        raise "unknown pattern #{@pattern.inspect}" unless name

        @message_name = name
      end

      def prepare_all
        dup.tap do |x|
          x.body = x.body.prepare_all
        end
      end

      def push_patterns(g)
        req = []
        dfs = []
        spl = nil
        blk = nil
        arguments.each do |a|
          case a
          when Patterns::BlockPass
            blk = a
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
        g.find_const :MethodPatterns

        receiver.construct(g)

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

        if blk
          blk.construct(g)
        else
          g.push_nil
        end

        g.send :new, 5
      end

      def bytecode(g)
        pos(g)

        defn = receiver.kind_of?(Patterns::Match) && receiver.value == :self

        g.push_cpath_top
        g.find_const :Atomy
        receiver.target(g)
        g.push_literal message_name.to_sym
        push_patterns(g)
        @body.prepare_all.construct(g)
        g.push_scope
        if defn
          g.push_variables
          g.send :method_visibility, 0
        else
          g.push_literal :public
        end
        g.push_scope
        g.send :active_path, 0
        g.push_int @line
        g.push_literal defn
        g.send :define_method, 9
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
