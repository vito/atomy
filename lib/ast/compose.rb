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
            @right.name.is_a?(Variable) && @right.name.name
          )
        else
          Send.new(
            @line,
            @left,
            [],
            @right.is_a?(Variable) && @right.name
          )
        end
      end

      def prepare_all
        x = prepare
        if x != self
          x.prepare_all
        else
          raise "something's probably amiss; no expansion: #{to_sexp.inspect}"
        end
      end

      def macro_name
        return :"atomy_macro::#{@right.name}" if @right.is_a? Variable
        return @left.macro_name if @left.is_a? Compose
        nil
      end
    end
  end
end
