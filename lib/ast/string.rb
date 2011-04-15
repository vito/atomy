module Atomy
  module AST
    class String < Node
      attributes :value
      generate

      def bytecode(g)
        pos(g)
        g.push_literal @value
        g.string_dup
      end

      def as_message(send)
        case send.receiver
        when Send
          MacroQuote.new(
            @line,
            send.receiver.method_name,
            @value,
            send.receiver.arguments.collect(&:name)
          )
        when Variable
          MacroQuote.new(
            @line,
            send.receiver.name,
            @value,
            []
          )
        end
      end
    end
  end
end
