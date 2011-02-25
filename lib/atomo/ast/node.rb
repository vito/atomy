module Atomo
  module AST
    class Node < Rubinius::AST::Node
      # yield this node's subnodes to a block recursively, and then itself
      # override this if for nodes with children, ie lists
      def recursively(&f)
        f.call(self)
      end

      # used to construct this expression in a quasiquote
      # g = generator, d = depth
      #
      # quasiquotes should increase depth, unquotes should decrease
      # an unquote at depth 0 should push the unquote's contents rather
      # than itself
      def construct(g, d)
        g.push_literal self
      end

      def get(g)
        self.class.name.split("::").each_with_index do |n, i|
          if i == 0
            g.push_const n.to_sym
          else
            g.find_const n.to_sym
          end
        end
      end

      def to_node
        self
      end
    end

    class Tree
      attr_accessor :nodes

      def initialize(nodes)
        @nodes = nodes
      end

      def bytecode(g)
        @nodes.each { |n| n.bytecode(g) }
      end

      def collect
        Tree.new(@nodes.collect { |n| yield n })
      end
    end
  end
end

class Object
  def to_node
    Atomo::AST::Primitive.new self
  end
end