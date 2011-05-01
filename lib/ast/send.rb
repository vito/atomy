module Atomy
  module AST
    class Send < Node
      children :receiver, [:arguments], :message?, :block?
      attributes :method_name?
      slots [:private, "false"], :namespace?
      generate

      def self.new(*args)
        super.resolve_message
      end

      def resolve_message
        res = self

        if res.message
          res = res.message.as_message(self)
          res.message = nil if res.method_name
        end

        res
      end

      def register_macro(body, let = false)
        Atomy::Macro.register(
          @method_name,
          ([@receiver] + @arguments).collect do |n|
            Atomy::Macro.macro_pattern n
          end,
          body,
          let
        )
      end

      def message_name
        Atomy.namespaced(@namespace, @method_name)
      end

      def to_send
        self
      end

      def prepare
        resolve.expand
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
