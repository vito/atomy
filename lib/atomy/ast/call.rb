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

      word = @name.to_word
      Send.new(
        @line,
        Primitive.new(@line, :self),
        args,
        word && word.text,
        splat,
        nil,
        true)
    end
  end
end
