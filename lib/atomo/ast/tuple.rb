module Atomo
  module AST
    class Tuple < AST::Node
      Atomo::Parser.register self

      def self.rule_name
        "tuple"
      end

      def initialize(elements)
        @elements = elements
        @line = 1 # TODO
      end

      def ==(b)
        b.kind_of?(Tuple) and \
        @elements == b.elements
      end

      attr_reader :elements

      def recursively(stop = nil, &f)
        return f.call self if stop and stop.call(self)

        f.call Tuple.new(
          @elements.collect do |n|
            n.recursively(stop, &f)
          end
        )
      end

      def construct(g, d)
        get(g)
        @elements.each do |e|
          e.construct(g, d)
        end
        g.make_array @elements.size
        g.send :new, 1
      end

      def self.grammar(g)
        g.tuple =
          g.seq(
            "(", :sp, g.t(:expression), :sp, g.any(";", ","),
            :sp, g.t(:expressions), :sp, ")"
          ) do |e, es|
            Tuple.new(es.unshift e)
          end | g.seq("(", :sp, ")") { Tuple.new([]) }
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
