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

      attr_reader :elements

      def self.grammar(g)
        g.tuple = g.seq("(", :sp, g.t(:expression), :sp, g.any(";", ","),
                                :sp, g.t(:expressions), :sp, ")") { |e, es|
                            Tuple.new(es.unshift e)
                          } | g.seq("(", :sp, ")") { Tuple.new([]) }
      end

      # TODO: make a Tuple or something, not an array
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
