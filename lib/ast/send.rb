module Atomy
  module AST
    class Send < Node
      children :receiver, [:arguments], :block?
      attributes :method_name
      slots [:private, "false"], :namespace?
      generate

      def register_macro(body)
        Atomy::Macro.register(
          @method_name,
          ([@receiver] + @arguments).collect do |n|
            Atomy::Macro.macro_pattern n
          end,
          body
        )
      end

      def message_name
        if @namespace && !@namespace.empty?
          @namespace + "/" + @method_name
        else
          @method_name
        end
      end

      def compile(g)
        expand.bytecode(g)
      end

      def bytecode(g)
        pos(g)

        @receiver.compile(g)

        block = @block
        splat = nil

        args = 0
        @arguments.each do |a|
          e = a.expand
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
          g.cast_array
          if block
            block.compile(g)
          else
            g.push_nil
          end
          g.send_with_splat message_name.to_sym, args, @private
        elsif block
          block.compile(g)
          g.send_with_block message_name.to_sym, args, @private
        else
          g.call_custom message_name.to_sym, args
        end
      end
    end
  end
end
