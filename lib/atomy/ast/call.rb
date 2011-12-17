module Atomy::AST
  class Call < Node
    children :name, [:arguments]
    generate

    def bytecode(g)
      to_send.bytecode(g)
    end

    def to_send
      args = @arguments.dup
      s = @arguments.last

      if s.is_a?(Prefix) && s.operator == :*
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
