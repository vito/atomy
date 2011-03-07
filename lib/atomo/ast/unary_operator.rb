# TODO: ensure binary sends do not end with @
module Atomo
  module AST
    class UnaryOperator < Node
      attr_reader :operator, :receiver

      def initialize(line, operator, receiver)
        @operator = operator
        @receiver = receiver
        @line = line
      end

      def ==(b)
        b.kind_of?(UnaryOperator) and \
        @operator == b.operator and \
        @receiver == b.receiver
      end

      def recursively(stop = nil, &f)
        return f.call self if stop and stop.call(self)

        f.call UnaryOperator.new(
          @line,
          @operator,
          @receiver.recursively(stop, &f)
        )
      end

      def construct(g, d)
        get(g)
        g.push_int @line
        g.push_literal @operator
        @receiver.construct(g, d)
        g.send :new, 3
      end

      def register_macro(body)
        Atomo::Macro.register(
          @operator + "@",
          [Atomo::Macro.macro_pattern(@receiver)],
          body
        )
      end

      def bytecode(g)
        pos(g)
        @receiver.bytecode(g)
        g.send(method_name.to_sym, 0)
      end

      def method_name
        @operator + "@"
      end
    end
  end
end
