module Atomo
  module AST
    class Tuple < Node
      attr_reader :elements

      def initialize(line, elements)
        @elements = elements
        @line = line
      end

      def ==(b)
        b.kind_of?(Tuple) and \
        @elements == b.elements
      end

      def recursively(stop = nil, &f)
        return f.call self if stop and stop.call(self)

        f.call Tuple.new(
          @line,
          @elements.collect do |n|
            n.recursively(stop, &f)
          end
        )
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

      def bytecode(g)
        pos(g)

        g.push_rubinius
        g.find_const :Tuple
        g.push @elements.size
        g.send :new, 1

        @elements.each_with_index do |e, i|
          g.dup
          g.push i
          e.bytecode(g)
          g.send :[]=, 2
          g.pop
        end
      end
    end
  end
end
