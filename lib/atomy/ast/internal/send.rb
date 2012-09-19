module Atomy
  module AST
    class Send < Node
      Operators = {
        :+    => :meta_send_op_plus,
        :-    => :meta_send_op_minus,
        :==   => :meta_send_op_equal,
        :===  => :meta_send_op_tequal,
        :<    => :meta_send_op_lt,
        :>    => :meta_send_op_gt
      }

      children :receiver, [:arguments], :splat?, :block?
      attributes :message_name, [:private, false]

      def bytecode(g, mod)
        pos(g)

        # private sends can be function calls
        if @private &&
            var = g.state.scope.search_local(:"#@message_name:function")
          var.get_bytecode(g)
          g.dup
          g.send :compiled_code, 0
          g.send :scope, 0
          mod.compile(g, @receiver)
          g.swap

          @arguments.each do |a|
            mod.compile(g, a)
          end

          if @splat
            mod.compile(g, @splat)
            g.send :to_a, 0

            if @block
              push_block(g, mod)
            else
              g.push_nil
            end

            g.send_with_splat :call_under, @arguments.size + 2
          elsif @block
            push_block(g, mod)
            g.send_with_block :call_under, @arguments.size + 2
          else
            g.send :call_under, @arguments.size + 2
          end

          return
        end

        mod.compile(g, @receiver)

        @arguments.each do |a|
          mod.compile(g, a)
        end

        if @splat
          mod.compile(g, @splat)
          g.send :to_a, 0

          if @block
            push_block(g, mod)
          else
            g.push_nil
          end

          g.send_with_splat @message_name, @arguments.size, @private
        elsif @block
          push_block(g, mod)
          g.send_with_block @message_name, @arguments.size, @private
        elsif meta = Operators[@message_name]
          g.__send__ meta, g.find_literal(@message_name)
        else
          g.send @message_name, @arguments.size, @private
        end
      end

      def to_send
        self
      end

      private

      def push_block(g, mod)
        if @block.is_a? Block
          @block.create_block(g, mod)
        else
          mod.compile(g, @block)
        end
      end
    end
  end
end
