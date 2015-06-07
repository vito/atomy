module Atomy::Grammar::AST
  class Node
    class << self
      def basename
        @basename ||= name.split("::").last.to_sym
      end
    end

    def each_child
    end

    def each_attribute
    end

    def children
      names = []

      each_child do |name, _|
        names << name
      end

      names
    end

    def attributes
      names = []

      each_attribute do |name, _|
        names << name
      end

      names
    end

    def accept(x)
      name = :"visit_#{self.class.basename.downcase}"

      if x.respond_to?(name)
        x.send(name, self)
      else
        x.visit(self)
      end
    end

    # Recreate the node, calling the block for sub-nodes and using its return
    # value in place of the node
    def through
      dup
    end
  end

  class Sequence
    def each_child
      yield :nodes, @nodes
    end

    def through
      self.class.new(nodes.collect { |n| yield n })
    end
  end

  class Number
    def each_attribute
      yield :value, @value
    end
  end

  class Literal
    def each_attribute
      yield :value, @value
    end
  end

  class Quote
    def each_child
      yield :node, @node
    end

    def through
      self.class.new(yield @node)
    end
  end

  class QuasiQuote
    def each_child
      yield :node, @node
    end

    def through
      self.class.new(yield @node)
    end
  end

  class Unquote
    def each_child
      yield :node, @node
    end

    def through
      self.class.new(yield @node)
    end
  end

  class Constant
    def each_attribute
      yield :text, @text
    end
  end

  class Word
    def each_attribute
      yield :text, @text
    end
  end

  class Prefix
    def each_attribute
      yield :operator, @operator
    end

    def each_child
      yield :node, @node
    end

    def through
      self.class.new(yield(@node), @operator)
    end
  end

  class Postfix
    def each_attribute
      yield :operator, @operator
    end

    def each_child
      yield :node, @node
    end

    def through
      self.class.new(yield(@node), @operator)
    end
  end

  class Infix
    def each_attribute
      yield :operator, @operator
    end

    def each_child
      yield :left, @left
      yield :right, @right
    end

    def through
      self.class.new(@left && yield(@left), yield(@right), @operator)
    end
  end

  class Block
    def each_child
      yield :nodes, @nodes
    end

    def through
      self.class.new(@nodes.collect { |n| yield n })
    end
  end

  class List
    def each_child
      yield :nodes, @nodes
    end

    def through
      self.class.new(@nodes.collect { |n| yield n })
    end
  end

  class Compose
    def each_child
      yield :left, @left
      yield :right, @right
    end

    def through
      self.class.new(yield(@left), yield(@right))
    end
  end

  class Apply
    def each_child
      yield :node, @node
      yield :arguments, @arguments
    end

    def through
      self.class.new(yield(@node), @arguments.collect { |a| yield a })
    end
  end

  class StringLiteral
    def each_attribute
      yield :value, @value
    end
  end
end
