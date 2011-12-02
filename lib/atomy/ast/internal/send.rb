module Atomy
  module AST
    class Send < Node
      children :receiver, [:arguments], :splat?, :block?
      attributes :message_name
      slots [:private, "false"]
      generate

      def bytecode(g)
        pos(g)

        @receiver.compile(g)

        @arguments.each do |a|
          a.compile(g)
        end

        if @splat
          @splat.compile(g)
          g.send :to_a, 0
          if block
            @block.compile(g)
          else
            g.push_nil
          end

          g.send_with_splat @message_name, @arguments.size, @private
        elsif @block
          @block.compile(g)
          g.send_with_block @message_name, @arguments.size, @private
        else
          g.send @message_name, @arguments.size, @private
        end
      end
    end
  end
end
