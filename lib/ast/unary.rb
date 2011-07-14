# TODO: ensure binary sends do not end with @
module Atomy
  module AST
    class Unary < Node
      children :receiver
      attributes :operator
      generate

      def macro_pattern
        x = unquote_children

        if @receiver.is_a?(Unary)
          x.receiver =
            Unary.unary_chain(@receiver)
        end

        Atomy::Patterns::QuasiQuote.new(
          Atomy::AST::QuasiQuote.new(
            @line,
            x
          )
        )
      end

      # !x
      #  to:
      # `(!~x)
      #
      # !?x
      #  to:
      # (`!?~x)
      def self.unary_chain(n)
        d = n.dup
        x = d
        while x.kind_of?(Atomy::AST::Unary)
          if x.receiver.kind_of?(Atomy::AST::Unary)
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

      def bytecode(g)
        pos(g)
        @receiver.compile(g)
        g.send message_name.to_sym, 0
      end

      def message_name
        @operator + "@"
      end
    end
  end
end
