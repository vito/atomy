module Atomo
  module AST
    class ForMacro < Node
      attr_reader :body

      def initialize(line, body)
        @body = body
        @line = line
      end

      def ==(b)
        b.kind_of?(ForMacro) and \
        @body == b.body
      end

      def construct(g, d)
        get(g)
        g.push_int @line
        @body.construct(g, d)
        g.send :new, 2
      end

      def recursively(stop = nil, &f)
        return f.call(self) if stop and stop.call(self)
        f.call ForMacro.new(@line, @body.recursively(&f))
      end

      def bytecode(g)
        pos(g)
        g.push_nil
      end
    end
  end
end
