module Atomo
  module AST
    class Ensure < Rubinius::AST::Ensure
      include NodeLike

      def recursively(stop = nil, &f)
        return f.call self if stop and stop.call(self)

        Ensure.new(
          @line,
          @body.recursively(stop, &f),
          @ensure.recursively(stop, &f)
        )
      end
    end
  end
end
