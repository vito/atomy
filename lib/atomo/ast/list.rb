module Atomo
  module AST
    class List < Node
      attr_reader :elements

      def initialize(line, elements)
        @elements = elements
        @line = line
      end

      def construct(g, d)
        get(g)
        g.push_int @line
        @elements.each do |e|
          e.construct(g, d)
        end
        g.make_array @elements.size
        g.send :new, 2
      end

      def ==(b)
        b.kind_of?(List) and \
        @elements == b.elements
      end

      def recursively(stop = nil, &f)
        return f.call self if stop and stop.call(self)

        f.call List.new(
          @line,
          @elements.collect do |n|
            n.recursively(stop, &f)
          end
        )
      end

      def bytecode(g)
        pos(g)

        @elements.each do |e|
          e.bytecode(g)
        end

        g.make_array @elements.size
      end
    end
  end
end
