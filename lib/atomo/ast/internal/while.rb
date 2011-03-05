module Atomo
  module AST
    class While < Rubinius::AST::While
      include NodeLike

      def initialize(line, cond, body, check_first = false)
        super
      end

      def recursively(stop = nil, &f)
        return f.call self if stop and stop.call(self)

        While.new(
          @line,
          @condition.recursively(stop, &f),
          @body.recursively(stop, &f),
          @check_first
        )
      end
    end
  end
end
