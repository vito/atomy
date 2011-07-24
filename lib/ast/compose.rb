module Atomy
  module AST
    class Compose < Node
      children :message, :receiver, [:arguments]
      slots [:headless, "false"]
      generate

      # treat the message as quoted by default so they don't have to do
      #   macro(x 'foo): ...
      # and allow an unquote to undo this
      def macro_pattern
        x =
          if @message.is_a?(Unquote)
            dup.unquoted_macro_pattern
          else
            unquote_children.tap do |x|
              x.message =
                @message.unquote_children
            end
          end

        # match self wildcard rather than wildcard
        if @headless
          x.receiver.expression =
            Atomy::AST::Quote.new(
              @line,
              Atomy::AST::Primitive.new(
                @line,
                :self
              )
            )
        elsif @receiver.is_a?(Compose)
          x.receiver =
            Compose.send_chain(@receiver)
        end

        Atomy::Patterns::QuasiQuote.new(
          Atomy::AST::QuasiQuote.new(
            @line,
            x
          )
        )
      end

      # see above
      def unquoted_macro_pattern
        @message = @message.expression
        unquote_children
      end

      # x(a)
      #  to:
      # `(x(~a))
      #
      # x(a) y(b)
      #  to:
      # `(x(~a) y(~b))
      #
      # x(&a) should bind the proc-arg
      def self.send_chain(n)
        if n.message.kind_of?(Block)
          return Atomy::AST::Unquote.new(n.line, n.to_pattern.to_node)
        end

        d = n.dup
        x = d
        while x.kind_of?(Atomy::AST::Compose)
          as = []
          x.arguments.each do |a|
            if a.kind_of?(Atomy::AST::Unary) && a.operator == "*"
              as << Atomy::AST::Splice.new(
                a.line,
                a.receiver.to_pattern.to_node
              )
            else
              as << Atomy::AST::Unquote.new(
                a.line,
                a.to_pattern.to_node
              )
            end
          end

          x.arguments = as

          unless x.message.kind_of?(Atomy::AST::Unquote)
            x.message =
              x.message.macro_pattern.quoted.expression
          end

          if x.receiver.kind_of?(Atomy::AST::Compose) and \
              !x.receiver.message.kind_of?(Block)
            y = x.receiver.dup
            x.receiver = y
            x = y
          else
            unless x.receiver.kind_of?(Atomy::AST::Primitive)
              x.receiver = Atomy::AST::Unquote.new(
                x.receiver.line,
                x.receiver.to_pattern.to_node
              )
            end
            break
          end
        end

        d
      end

      def to_send
        Send.new(
          @line,
          @receiver,
          @arguments,
          @message.is_a?(Variable) && @message.name,
          nil,
          @headless
        )
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
        return :"atomy_macro::#{@message.name}" if @message.is_a? Variable
        return @receiver.macro_name if @receiver.is_a? Compose
        nil
      end
    end
  end
end
