module Atomy::AST
  class Call < Node
    children :name, [:arguments]
    generate

    def to_send
      Send.new(
        @line,
        Primitive.new(@line, :self),
        @arguments,
        @name.is_a?(Variable) && @name.name,
        nil,
        true
      )
    end
  end
end
