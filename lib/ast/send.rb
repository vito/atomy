module Atomy
  module AST
    class Send < Node
      children :receiver, [:arguments], :block?
      attributes :method_name, [:private, false]
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

      def bytecode(g)
        pos(g)

        @receiver.bytecode(g)
        block = @block
        if @arguments.last.kind_of? BlockPass
          block = @arguments.pop
        end

        splat = nil
        if (splats = @arguments.select { |n| n.kind_of?(Splat) }).size > 0
          splat = splats[0]
          @arguments.reject! { |n| n.kind_of?(Splat) }
        end

        @arguments.each do |a|
          a.bytecode(g)
        end

        if splat
          splat.bytecode(g)
          g.cast_array
          if block
            block.bytecode(g)
          else
            g.push_nil
          end
          g.send_with_splat @method_name.to_sym, @arguments.size, @private
        elsif block
          block.bytecode(g)
          g.send_with_block @method_name.to_sym, @arguments.size, @private
        else
          g.send @method_name.to_sym, @arguments.size, @private
        end
      end
    end
  end
end
