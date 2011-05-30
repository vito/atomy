# TODO: ensure binary sends do not end with @
module Atomy
  module AST
    class Unary < Node
      children :receiver
      attributes :operator
      slots :namespace?
      generate

      def message_name
        Atomy.namespaced(@namespace, @operator)
      end

      def macro_pattern
        x = super

        if @receiver.is_a?(Unary)
          x.quoted.expression.receiver =
            Unary.unary_chain(@receiver)
        end

        x
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
        if @namespace == "_"
          g.send @operator.to_sym, 0
        else
          g.push_literal message_name.to_sym
          g.send :atomy_send, 1
          #g.call_custom message_name.to_sym, 0
        end
      end

      def message_name
        @operator + "@"
      end
    end
  end
end
