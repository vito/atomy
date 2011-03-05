module Atomo
  module AST
    class Return < Rubinius::AST::Return
      include NodeLike

      def initialize(line, expr)
        super
      end

      def recursively(stop = nil, &f)
        return f.call self if stop and stop.call(self)

        Return.new(
          @line,
          @value.recursively(stop, &f)
        )
      end
    end
  end
end
