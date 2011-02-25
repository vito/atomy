module Atomo
  module AST
    class Node < Rubinius::AST::Node
      # yield this node's subnodes to a block recursively, and then itself
      # override this if for nodes with children, ie lists
      def recursively(&f)
        f.call(self)
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