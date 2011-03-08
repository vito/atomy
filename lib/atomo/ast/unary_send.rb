module Atomo
  module AST
    class UnarySend < Node
      attr_reader :receiver, :method_name, :arguments, :block, :private

      def initialize(line, receiver, name, arguments, block = nil, privat = false)
        @receiver = receiver
        @method_name = name
        @arguments = arguments
        @block = block unless block == []
        @private = privat
        @line = line
      end

      def construct(g, d)
        get(g)
        g.push_int @line
        @receiver.construct(g, d)
        g.push_literal @method_name
        @arguments.each do |a|
          a.construct(g, d)
        end
        g.make_array @arguments.size

        if @block
          @block.construct(g, d)
        else
          g.push_nil
        end

        g.push_literal @private
        g.send :new, 6
      end

      def ==(b)
        b.kind_of?(UnarySend) and \
        @receiver == b.receiver and \
        @method_name == b.method_name and \
        @arguments == b.arguments and \
        @block == b.block and \
        @private == b.private
      end

      def register_macro(body)
        Atomo::Macro.register(
          @method_name,
          ([@receiver] + @arguments).collect do |n|
            Atomo::Macro.macro_pattern n
          end,
          body
        )
      end

      def recursively(stop = nil, &f)
        return f.call self if stop and stop.call(self)

        f.call UnarySend.new(
          @line,
          @receiver.recursively(stop, &f),
          @method_name,
          @arguments.collect do |n|
            n.recursively(stop, &f)
          end,
          @block ? @block.recursively(stop, &f) : nil,
          @private
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
