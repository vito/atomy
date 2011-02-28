module Atomo
  module AST
    module NodeLike
      attr_accessor :line

      # yield this node's subnodes to a block recursively, and then itself
      # override this if for nodes with children, ie lists
      #
      # stop = predicate to determine whether to stop at a node before
      # recursing into its children
      def recursively(stop = nil, &f)
        f.call(self)
      end

      # used to construct this expression in a quasiquote
      # g = generator, d = depth
      #
      # quasiquotes should increase depth, unquotes should decrease
      # an unquote at depth 0 should push the unquote's contents rather
      # than itself
      def construct(g, d)
        pos(g)
        g.push_literal self
      end

      def through_quotes(stop_ = nil, &f)
        stop = proc { |x|
          (stop_ and stop_.call(x)) or \
            x.kind_of?(AST::QuasiQuote) or \
            x.kind_of?(AST::Unquote)
        }

        depth = 0
        search = nil
        scan = proc do |x|
          case x
          when Atomo::AST::QuasiQuote
            depth += 1
            Atomo::AST::QuasiQuote.new(
              x.line,
              x.expression.recursively(stop, &search)
            )
          else
            f.call(x)
          end
        end

        search = proc do |x|
          case x
          when Atomo::AST::QuasiQuote
            depth += 1
            Atomo::AST::QuasiQuote.new(
              x.line,
              x.expression.recursively(stop, &search)
            )
          when Atomo::AST::Unquote
            depth -= 1
            if depth == 0
              Atomo::AST::Unquote.new(
                x.line,
                x.expression.recursively(stop, &scan)
              )
            else
              Atomo::AST::Unquote.new(
                x.line,
                x.expression.recursively(stop, &search)
              )
            end
          else
            x
          end
        end

        recursively(stop, &scan)
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

    class Node < Rubinius::AST::Node
      include NodeLike
    end

    class Tree
      attr_accessor :nodes

      def initialize(nodes)
        @nodes = Array(nodes)
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
    Atomo::AST::Primitive.new -1, self
  end
end
