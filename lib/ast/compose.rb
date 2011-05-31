module Atomy
  module AST
    class Compose < Node
      children :message, :receiver, [:arguments]
      slots [:headless, "false"]
      generate

      # treat the message as quoted by default so they don't have to do
      #   macro(x 'foo): ...
      # and allow an unquote to undo this
      def macro_pattern(unquoted = false)
        return super() if unquoted

        x =
          if @message.is_a?(Unquote)
            dup.unquoted_macro_pattern
          else
            super().tap do |x|
              x.quoted.expression.message =
                @message.macro_pattern.quoted.expression
            end
          end

        # match self wildcard rather than wildcard
        if @headless
          x.quoted.expression.receiver.expression =
            Atomy::AST::Quote.new(
              @line,
              Atomy::AST::Primitive.new(
                @line,
                :self
              )
            )
        elsif @receiver.is_a?(Compose)
          x.quoted.expression.receiver =
            Compose.send_chain(@receiver)
        end

        ## have do(&x) match the block portion
        #last = x.quoted.expression.arguments.last
        #if last and blk = last.expression and blk.is_a?(Unary) and \
              #blk.operator == "&"
          #x.quoted.expression.block =
            #Atomy::AST::Unquote.new(
              #blk.line,
              #blk.receiver
            #)

          #x.quoted.expression.arguments.pop
        #end

        x
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
          return Atomy::AST::Unquote.new(n.line, n)
        end

        d = n.dup
        x = d
        while x.kind_of?(Atomy::AST::Compose)
          as = []
          x.arguments.each do |a|
            if a.kind_of?(Atomy::AST::Unary) && a.operator == "*"
              as << Atomy::AST::Splice.new(
                a.line,
                a.receiver
              )
            else
              as << Atomy::AST::Unquote.new(
                a.line,
                a
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
                x.receiver
              )
            end
            break
          end
        end

        d
      end

      # see above
      def unquoted_macro_pattern
        @message = @message.expression
        macro_pattern(true)
      end

      def to_send
        Send.new(
          @line,
          @receiver,
          @arguments,
          @message.is_a?(Variable) && @message.name,
          nil,
          @headless,
          @message.namespace
        )
      end

      def namespace_symbol
        @message.namespace_symbol
      end

      def resolve
        dup.tap do |y|
          y.message = y.message.resolve
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
    end
  end
end
