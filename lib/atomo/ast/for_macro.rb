module Atomo
  module AST
    class ForMacro < Node
      attr_reader :body

      def initialize(body)
        @body = body
        @line = 1 # TODO
      end

      def ==(b)
        b.kind_of?(ForMacro) and \
        @body == b.body
      end

      def construct(g, d)
        get(g)
        @body.construct(g, d)
        g.send :new, 1
      end

      def recursively(stop = nil, &f)
        return f.call(self) if stop and stop.call(self)
        f.call ForMacro.new(@body.recursively(&f))
      end

      def bytecode(g)
        pos(g)
        g.push_nil
      end
    end
  end
end
