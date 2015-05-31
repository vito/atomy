require "atomy/grammar"

module Atomy::Grammar::AST
  class Sequence
    def to_s
      @nodes.join(", ")
    end
  end

  class Number
    def to_s
      @value.to_s
    end
  end

  class Literal
    def to_s
      @value.to_s
    end
  end

  class Quote
    def to_s
      "'#@node"
    end
  end

  class QuasiQuote
    def to_s
      "`#@node"
    end
  end

  class Unquote
    def to_s
      "~#@node"
    end
  end

  class Constant
    def to_s
      @text.to_s
    end
  end

  class Word
    def to_s
      word = @text.to_s
      word[0] + word[1..-1].tr("_", "-")
    end
  end

  class Prefix
    def to_s
      "#@operator#@node"
    end
  end

  class Postfix
    def to_s
      "#@node#@operator"
    end
  end

  class Infix
    def to_s
      if @left
        "(#@left #@operator #@right)"
      else
        "(#@operator #@right)"
      end
    end
  end

  class Block
    def to_s
      if @nodes.empty?
        "{}"
      else
        "{ #{@nodes.join(", ")} }"
      end
    end
  end

  class List
    def to_s
      "[#{@nodes.join(", ")}]"
    end
  end

  class Compose
    def to_s
      "(#@left #@right)"
    end
  end

  class Apply
    def to_s
      "#@node(#{@arguments.join(", ")})"
    end
  end

  class StringLiteral
    def to_s
      @value.inspect
    end
  end
end
