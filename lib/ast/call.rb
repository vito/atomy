module Atomy::AST
  class Call < Node
    children :name, [:arguments]
    generate

    def to_send
      Send.new(
        @line,
        Primitive.new(@line, :self),
        @arguments,
        @name.is_a?(Word) && @name.text,
        nil,
        true
      )
    end

    def macro_name
      return :"atomy_macro::#{@name.text}" if @name.is_a? Word
      @name.macro_name
    end
  end
end
