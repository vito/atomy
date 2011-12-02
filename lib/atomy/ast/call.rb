module Atomy::AST
  class Call < Node
    children :name, [:arguments]
    generate

    def to_send
      args = @arguments.dup
      s = @arguments.last

      if s.is_a?(Unary) && s.operator == :*
        splat = s.receiver
        args.pop
      else
        splat = nil
      end

      Send.new(
        @line,
        Primitive.new(@line, :self),
        args,
        @name.is_a?(Word) && @name.text,
        splat,
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
