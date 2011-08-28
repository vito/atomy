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

    def macro_name
      return :"atomy_macro::#{@name.name}" if @name.is_a? Variable
      @name.macro_name
    end
  end
end
