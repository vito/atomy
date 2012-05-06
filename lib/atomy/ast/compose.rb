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
            s.private = false
          end
        when List
          args = @right.elements
          s = args.last
          if s.is_a?(Prefix) && s.operator == :*
            splat = s.receiver
            args = args[0..-2]
          else
            splat = nil
          end

          Send.new(
            @line,
            @left,
            args,
            :[],
            splat)
        else
          word = @right.to_word

          Send.new(
            @line,
            @left,
            [],
            word && word.text)
        end
      end
    end
  end
end
