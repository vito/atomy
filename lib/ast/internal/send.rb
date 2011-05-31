module Atomy
  module AST
    class Send < Node
      children :receiver, [:arguments], :block?
      attributes :message_name
      slots [:private, "false"], :namespace?
      generate

      def namespaced
        Atomy.namespaced(@namespace, @message_name)
      end

      def bytecode(g)
        pos(g)

        @receiver.compile(g)

        block = @block
        splat = nil

        unless @namespace == "_"
          g.push_literal namespaced.to_sym
        end

        args = 0
        @arguments.each do |a|
          e = a.prepare
          if e.kind_of?(BlockPass)
            block = e
            break
          elsif e.kind_of?(Splat)
            splat = e
            break
          end

          e.bytecode(g)
          args += 1
        end

        if splat
          splat.compile(g)
          if block
            block.compile(g)
          else
            g.push_nil
          end
          if @namespace == "_"
            g.send_with_splat @message_name.to_sym, args, @private
          else
            g.send_with_splat :atomy_send, args + 1
            #g.call_custom_with_splat namespaced.to_sym, args
          end
        elsif block
          block.compile(g)
          if @namespace == "_"
            g.send_with_block @message_name.to_sym, args, @private
          else
            g.send_with_block :atomy_send, args + 1
            #g.call_custom_with_block namespaced.to_sym, args
          end
        elsif @namespace == "_"
          g.send @message_name.to_sym, args, @private
        else
          g.send :atomy_send, args + 1
          #g.call_custom namespaced.to_sym, args
        end
      end
    end
  end
end
