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
            name = :[]
          end
        else
          name = @pattern.message_name
        end

        raise "unknown pattern #{@pattern.inspect}" unless name

        @message_name = name
      end

      def compile_body(g)
        meth = new_generator(g, message_name)

        pos(meth)

        meth.push_state Rubinius::AST::ClosedScope.new(@line)
        # TODO: push a super that calls message_name, not the branch's name
        #meth.state.push_super self
        meth.definition_line(@line)

        meth.state.push_name message_name

        meth.state.scope.new_local(:arguments)

        meth.splat_index = 0
        meth.total_args = 0
        meth.required_args = 0

        if receiver.bindings > 0
          meth.push_self
          receiver.deconstruct(meth)
        end

        if arguments.size > 0
          meth.push_local(0)
          arguments.each do |a|
            case a
            when Patterns::BlockPass
              meth.push_block_arg
              a.deconstruct(meth)
            when Patterns::Splat
              meth.dup
              a.deconstruct(meth)
            else
              meth.shift_array
              a.deconstruct(meth)
            end
          end

          meth.pop
        end

        @body.compile(meth)

        meth.state.pop_name

        meth.ret
        meth.close

        meth.local_count = 1
        meth.local_names = meth.state.scope.local_names
        meth.use_detected

        raise "mismatch: (#{meth.local_names.inspect}, #{meth.local_count})" unless meth.local_names.size == meth.local_count

        meth.pop_state

        meth
      end

      def push_method(g)
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
        g.find_const :Branch

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
        g.push_literal message_name
        push_method(g)

        g.push_generator compile_body(g)
        g.dup
        g.push_scope
        g.send :"scope=", 1
        g.pop

        if defn
          g.push_variables
          g.send :method_visibility, 0
        else
          g.push_literal :public
        end
        g.push_scope
        g.push_literal defn
        g.send :define_branch, 7
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
