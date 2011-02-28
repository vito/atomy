module Atomo
  module AST
    class Catch < Rubinius::AST::Rescue
      include NodeLike

      def initialize(line, body, rescue_body, else_body = nil)
        super(line, body, Rubinius::AST::RescueCondition.new(line, nil, rescue_body, nil), else_body)
      end

      def recursively(stop = nil, &f)
        return f.call self if stop and stop.call(self)

        Catch.new(
          @line,
          @body.recursively(stop, &f),
          @rescue.body.recursively(stop, &f),
          @else ? @else.recursively(stop, &f) : nil
        )
      end
    end
  end
end