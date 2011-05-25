module Atomy::AST
  class Literal < Node
    attributes :value
    generate

    def bytecode(g)
      pos(g)
      g.push_literal @value
    end
  end

  class String < Literal
    attributes :value, :raw?
    generate

    def bytecode(g)
      super
      g.string_dup
    end

    def as_message(send)
      MacroQuote.new(
        @line,
        send.receiver.name,
        @raw || @value,
        send.arguments.collect(&:name),
        @value
      )
    end
  end
end
