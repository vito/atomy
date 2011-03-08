module Atomo
  module AST
    class Metaclass < Rubinius::AST::SClass
      include NodeLike

      def initialize(line, receiver, body)
        @line = line
        @receiver = receiver
        @body = Rubinius::AST::SClassScope.new @line, body
        @_body = body
      end

      def construct(g, d = nil)
        get(g)
        g.push_int @line
        @receiver.construct(g, d)
        @_body.construct(g, d)
        g.send :new, 3
      end

      def recursively(stop = nil, &f)
        return f.call self if stop and stop.call(self)

        Metaclass.new(
          @line,
          @receiver,
          @body.body.recursively(stop, &f)
        )
      end
    end
  end
end
