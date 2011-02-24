module Atomo
  module AST
    class Node < Rubinius::AST::Node
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
