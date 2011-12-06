module Atomy
  module AST
    class Compose < Node
      children :left, :right
      generate

      def to_send
        case @right
        when Call
          @right.to_send.tap do |s|
            s.receiver = @left
          end
        when List
          args = @right.elements
          s = args.last
          if s.is_a?(Prefix) && s.operator == :*
            splat = s.receiver
            args.pop
          else
            splat = nil
          end

          Send.new(
            @line,
            @left,
            args,
            :[],
            splat
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
