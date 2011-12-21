module Atomy
  module AST
    class Define < Node
      children :body, :receiver, [:arguments], :block?
      attributes :method_name, [:defn, "false"]
      generate

      def argument_patterns
        @argument_patterns ||= @arguments.collect(&:to_pattern)
      end

      def receiver_pattern
        @receiver_pattern ||= @receiver.to_pattern
      end

      def block_pattern
        @block && @block.to_pattern
      end

      def compile_body(g)
        meth = new_generator(g, @method_name)

        pos(meth)

        meth.push_state Rubinius::AST::ClosedScope.new(@line)
        # TODO: push a super that calls method_name, not the branch's name
        #meth.state.push_super self
        meth.definition_line(@line)

        meth.state.push_name @method_name

        meth.state.scope.new_local(:arguments)

        meth.splat_index = 0
        meth.total_args = 0
        meth.required_args = 0

        if receiver_pattern.binds?
          meth.push_self
          receiver_pattern.deconstruct(meth)
        end

        if block_pattern
          meth.push_block_arg
          block_pattern.deconstruct(meth)
        end

        if argument_patterns.size > 0
          meth.push_local(0)
          argument_patterns.each do |a|
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
        argument_patterns.each do |a|
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

        receiver_pattern.construct(g)

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

        if block_pattern
          block_pattern.construct(g)
        else
          g.push_nil
        end

        g.send :new, 5
      end

      def bytecode(g)
        pos(g)

        g.push_cpath_top
        g.find_const :Atomy
        if @defn
          g.push_self
        else
          receiver_pattern.target(g)
        end
        g.push_literal @method_name
        push_method(g)

        g.push_generator compile_body(g)
        g.dup
        g.push_scope
        g.send :"scope=", 1
        g.pop

        if @defn
          g.push_variables
          g.send :method_visibility, 0
        else
          g.push_literal :public
        end
        g.push_scope
        g.push_literal @defn
        g.send :define_branch, 7
      end

      def local_count
        local_names.size
      end

      def local_names
        argument_patterns.inject(receiver_pattern.local_names) do |acc, a|
          acc + a.local_names
        end
      end
    end
  end
end
