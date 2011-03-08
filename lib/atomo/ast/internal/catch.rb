module Atomo
  module AST
    class Catch < Rubinius::AST::Rescue
      include NodeLike

      def initialize(line, body, rescue_body, else_body = nil)
        super(line, body, Rubinius::AST::RescueCondition.new(line, nil, rescue_body, nil), else_body)
        @_body = body
        @_rescue = rescue_body
        @_else = else_body
      end

      def construct(g, d = nil)
        get(g)
        g.push_int @line
        @_body.construct(g, d)
        @_rescue.construct(g, d)
        if @_else
          @_else.construct(g, d)
        else
          g.push_nil
        end
        g.send :new, 4
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