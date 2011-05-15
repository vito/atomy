module Atomy
  module AST
    class String < Node
      attributes :value, :raw?
      generate

      def bytecode(g)
        pos(g)
        g.push_literal @value
        g.string_dup
      end

      def as_message(send)
        MacroQuote.new(
          @line,
          send.receiver.name,
          @raw || @value,
          send.arguments.collect(&:name)
        )
      end
    end
  end
end
