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
      attributes :message_name, [:private, "false"]
      generate

      def bytecode(g)
        pos(g)

        # private sends get special semantics
        # see Atomy.send_message
        if @private
          g.push_cpath_top
          g.find_const :Atomy

          @receiver.compile(g)
          g.push_scope
          g.push_literal @message_name

          @arguments.each do |a|
            a.compile(g)
          end

          if @splat
            @splat.compile(g)
            g.send :to_a, 0

            if @block
              push_block(g)
            else
              g.push_nil
            end

            g.send_with_splat :send_message, @arguments.size + 3
          elsif @block
            push_block(g)
            g.send_with_block :send_message, @arguments.size + 3
          else
            g.send :send_message, @arguments.size + 3
          end

          return
        end

        @receiver.compile(g)

        @arguments.each do |a|
          a.compile(g)
        end

        if @splat
          @splat.compile(g)
          g.send :to_a, 0

          if @block
            push_block(g)
          else
            g.push_nil
          end

          g.send_with_splat @message_name, @arguments.size
        elsif @block
          push_block(g)
          g.send_with_block @message_name, @arguments.size
        elsif meta = Operators[@message_name]
          g.__send__ meta, g.find_literal(@message_name)
        else
          g.send @message_name, @arguments.size
        end
      end

      private

      def push_block(g)
        if @block.is_a? Block
          @block.create_block(g)
        else
          @block.compile(g)
        end
      end
    end
  end
end
