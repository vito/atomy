module Atomy
  module AST
    class Send < Node
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
              @block.compile(g)
            else
              g.push_nil
            end

            g.send_with_splat :send_message, @arguments.size + 3
          elsif @block
            @block.compile(g)
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
            @block.compile(g)
          else
            g.push_nil
          end

          g.send_with_splat @message_name, @arguments.size
        elsif @block
          @block.compile(g)
          g.send_with_block @message_name, @arguments.size
        else
          g.send @message_name, @arguments.size
        end
      end
    end
  end
end
