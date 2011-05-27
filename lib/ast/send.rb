module Atomy
  module AST
    class Send < Node
      children :message, :receiver, [:arguments], :block?
      attributes :method_name?
      slots [:private, "false"], :namespace?
      generate

      def macro_pattern
        super.tap do |x|
          x.quoted.expression.message =
            @message.macro_pattern.quoted.expression
        end
      end

      def expand
        case @message
          # TODO: do this for things that don't define macros
        when Variable
          self.dup.tap do |x|
            x.method_name = @message.name
          end
        else
          super
        end
      end

      def message_name
        Atomy.namespaced(@namespace, @method_name)
      end

      def to_send
        self
      end

      def expandable?
        true
      end

      def bytecode(g)
        pos(g)

        @receiver.compile(g)

        block = @block
        splat = nil

        unless @namespace == "_"
          g.push_literal message_name.to_sym
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
            g.send_with_splat @method_name.to_sym, args, @private
          else
            g.send_with_splat :atomy_send, args + 1
            #g.call_custom_with_splat message_name.to_sym, args
          end
        elsif block
          block.compile(g)
          if @namespace == "_"
            g.send_with_block @method_name.to_sym, args, @private
          else
            g.send_with_block :atomy_send, args + 1
            #g.call_custom_with_block message_name.to_sym, args
          end
        elsif @namespace == "_"
          g.send @method_name.to_sym, args, @private
        else
          g.send :atomy_send, args + 1
          #g.call_custom message_name.to_sym, args
        end
      end
    end
  end
end
