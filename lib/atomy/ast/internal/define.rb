module Atomy
  module AST
    class Define < Node
      children :pattern, :body
      generate

      def arguments
        @arguments ||=
          get_arguments(@pattern).collect(&:to_pattern) ||
            raise("unknown pattern #{@pattern.inspect}")
      end

      def receiver
        @receiver ||=
          get_receiver(@pattern).to_pattern ||
            raise("unknown pattern #{@pattern.inspect}")
      end

      def message_name
        @message_name ||=
          get_message_name(@pattern) ||
            raise("unknown pattern #{@pattern.inspect}")
      end

      def block
        @block ||= get_block(@pattern)
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

        if receiver.binds?
          meth.push_self
          receiver.deconstruct(meth)
        end

        if block
          meth.push_block_arg
          block.deconstruct(meth)
        end

        if arguments.size > 0
          meth.push_local(0)
          arguments.each do |a|
            case a
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

        unless meth.local_names.size == meth.local_count
          raise "locals mismatch: (#{meth.local_names}, #{meth.local_count})" 
        end

        meth.pop_state

        meth
      end

      def push_method(g)
        req = []
        dfs = []
        spl = nil
        arguments.each do |a|
          case a
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

        if block
          block.construct(g)
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

    private

      def get_arguments(x)
        case x
        when Binary
          [x.rhs]
        when Word, Prefix, Postfix
          []
        when Call
          x.arguments
        when Compose
          case x.right
          when Call
            x.right.arguments
          when Word
            []
          when List
            x.right.elements
          when Compose
            if x.right.right.is_a?(Prefix) and x.right.right.operator == :&
              get_arguments(x.right.left)
            end
          when Prefix, Postfix
            get_arguments(x.left)
          end
        end
      end

      def get_receiver(x)
        case x
        when Binary
          x.lhs
        when Prefix, Postfix
          x.receiver
        when Call, Word
          Primitive.new(x.line, :self)
        when Compose
          if x.right.is_a?(Prefix) and x.right.operator == :&
            get_receiver(x.left)
          else
            x.left
          end
        end
      end

      def get_message_name(x)
        case x
        when Word
          x.text
        when Call
          x.name.text
        when Compose
          case x.right
          when Word
            x.right.text
          when Call
            x.right.name.text
          when List
            :[]
          when Compose
            if x.right.right.is_a?(Prefix) and x.right.right.operator == :&
              get_message_name(x.right.left)
            end
          when Prefix, Postfix
            get_message_name(x.left)
          end
        else
          x.message_name
        end
      end

      def get_block(x)
        case x
        when Compose
          case x.right
          when Compose
            if x.right.right.is_a?(Prefix) and x.right.right.operator == :&
              x.right.right.to_pattern
            end
          when Prefix
            x.right.to_pattern
          end
        end
      end
    end
  end
end
