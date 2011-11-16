module Atomy
  module AST
    class Compose < Node
      children :left, :right
      generate

      def to_send
        case @right
        when Call
          Send.new(
            @line,
            @left,
            @right.arguments,
            @right.name.is_a?(Word) && @right.name.text
          )
        else
          Send.new(
            @line,
            @left,
            [],
            @right.is_a?(Word) && @right.text
          )
        end
      end

      def macro_name
        return :"atomy_macro::#{@right.text}" if @right.is_a? Word
        @right.macro_name || @left.macro_name
      end
    end
  end
end
