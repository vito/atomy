module Atomo
  module AST
    class List < AST::Node
      Atomo::Parser.register self

      def self.rule_name
        "list"
      end

      def initialize(elements)
        @elements = elements
        @line = 1 # TODO
      end

      attr_reader :elements

      def recursively(&f)
        f.call List.new(
          @elements.collect do |n|
            n.recursively(&f)
          end
        )
      end

      def self.grammar(g)
        g.list =
          g.seq("[", :sp, g.t(:some_expressions), :sp, "]") do |e|
            List.new(e)
          end
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
