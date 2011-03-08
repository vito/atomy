module Atomo
  module AST
    class KeywordSend < Node
      attr_reader :receiver, :names, :arguments, :private

      def initialize(line, receiver, names, arguments, privat = false)
        @receiver = receiver
        @names = names
        @arguments = arguments
        @private = privat
        @line = line
      end

      def construct(g, d)
        get(g)
        g.push_int @line
        @receiver.construct(g, d)
        @names.each do |n|
          g.push_literal n
        end
        g.make_array @names.size
        @arguments.each do |a|
          a.construct(g, d)
        end
        g.make_array @arguments.size
        g.push_literal @private
        g.send :new, 5
      end

      def ==(b)
        b.kind_of?(KeywordSend) and \
        @receiver == b.receiver and \
        @names == b.names and \
        @arguments == b.arguments
      end

      def register_macro(body)
        Atomo::Macro.register(
          method_name,
          ([@receiver] + @arguments).collect do |n|
            Atomo::Macro.macro_pattern n
          end,
          body
        )
      end

      def recursively(stop = nil, &f)
        return f.call self if stop and stop.call(self)

        f.call KeywordSend.new(
          @line,
          @receiver.recursively(stop, &f),
          @names,
          @arguments.collect do |n|
            n.recursively(stop, &f)
          end,
          @private
        )
      end

      def bytecode(g)
        pos(g)

        @receiver.bytecode(g)

        @arguments.each do |a|
          a.bytecode(g)
        end

        g.send method_name.to_sym, @arguments.size, @private
      end

      def method_name
        @names.collect { |n| n + ":" }.join
      end
    end
  end
end
