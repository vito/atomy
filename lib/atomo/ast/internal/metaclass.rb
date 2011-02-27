module Atomo
  module AST
    class Metaclass < Rubinius::AST::SClass
      include NodeLike

      def initialize(receiver, body)
        @line = 1 # TODO
        @receiver = receiver
        @body = Rubinius::AST::SClassScope.new @line, body
      end

      def recursively(stop = nil, &f)
        return f.call self if stop and stop.call(self)

        Metaclass.new(
          @receiver,
          @body.body.recursively(stop, &f)
        )
      end
    end
  end
end