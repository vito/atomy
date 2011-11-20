module Atomy
  module AST
    class Send < Node
      children :receiver, [:arguments], :block?
      attributes :message_name
      slots [:private, "false"]
      generate

      def bytecode(g)
        pos(g)

        @receiver.compile(g)

        block = @block
        splat = nil

        args = 0
        @arguments.each do |a|
          e = a.prepare
          if e.kind_of?(BlockPass)
            block = e
            next
          elsif e.kind_of?(Splat)
            splat = e
            next
          end

          e.bytecode(g)
          args += 1
        end

        if splat
          splat.compile(g)
          g.send :to_a, 0
          if block
            block.compile(g)
          else
            g.push_nil
          end

          g.send_with_splat @message_name, args, @private
        elsif block
          block.compile(g)
          g.send_with_block @message_name, args, @private
        else
          g.send @message_name, args, @private
        end
      end
    end
  end
end
