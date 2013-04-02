require "atomy/grammar"

module Atomy::Grammar::AST
  class Node
  end

  class Sequence
    def ==(other)
      super || other.is_a?(self.class) && @nodes == other.nodes
    end
  end

  class Number
    def ==(other)
      super || other.is_a?(self.class) && @value == other.value
    end
  end

  class Literal
    def ==(other)
      super || other.is_a?(self.class) && @value == other.value
    end
  end

  class Quote
    def ==(other)
      super || other.is_a?(self.class) && @node == other.node
    end
  end

  class QuasiQuote
    def ==(other)
      super || other.is_a?(self.class) && @node == other.node
    end
  end

  class Unquote
    def ==(other)
      super || other.is_a?(self.class) && @node == other.node
    end
  end

  class Constant
    def ==(other)
      super || other.is_a?(self.class) && @text == other.text
    end
  end

  class Word
    def ==(other)
      super || other.is_a?(self.class) && @text == other.text
    end
  end

  class Prefix
    def ==(other)
      super || other.is_a?(self.class) && \
        @operator == other.operator && \
        @node == other.node
    end
  end

  class Postfix
    def ==(other)
      super || other.is_a?(self.class) && \
        @operator == other.operator && \
        @node == other.node
    end
  end

  class Infix
    def ==(other)
      super || other.is_a?(self.class) && \
        @operator == other.operator && \
        @left == other.left && \
        @right == other.right
    end
  end

  class Block
    def ==(other)
      super || other.is_a?(self.class) && @nodes == other.nodes
    end
  end

  class List
    def ==(other)
      super || other.is_a?(self.class) && @nodes == other.nodes
    end
  end

  class Compose
    def ==(other)
      super || other.is_a?(self.class) && \
        @left == other.left && \
        @right == other.right
    end
  end

  class Apply
    def ==(other)
      super || other.is_a?(self.class) && \
        @node == other.node && \
        @arguments == other.arguments
    end
  end

  class StringLiteral
    def ==(other)
      super || other.is_a?(self.class) && @value == other.value
    end
  end
end
