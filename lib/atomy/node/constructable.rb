require "atomy/grammar"

module Atomy::Grammar::AST
  class Node
    def construct(gen)
      raise "no #construct for #{self.class}"
    end

    private
    
    def push_node(gen, name)
      gen.push_cpath_top
      gen.find_const(:Atomy)
      gen.find_const(:Grammar)
      gen.find_const(:AST)
      gen.find_const(name)
    end
  end

  class Sequence
    def construct(gen)
      push_node(gen, :Sequence)
      @nodes.each do |node|
        node.construct(gen)
      end
      gen.make_array(@nodes.size)
      gen.send(:new, 1)
    end
  end

  class Number
    def construct(gen)
      push_node(gen, :Number)
      gen.push_int(@value)
      gen.send(:new, 1)
    end
  end

  class Literal
    def construct(gen)
      push_node(gen, :Literal)
      gen.push_literal(@value)
      gen.send(:new, 1)
    end
  end

  class Quote
    def construct(gen)
      push_node(gen, :Quote)
      @node.construct(gen)
      gen.send(:new, 1)
    end
  end

  class QuasiQuote
    def construct(gen)
      push_node(gen, :QuasiQuote)
      @node.construct(gen)
      gen.send(:new, 1)
    end
  end

  class Unquote
    def construct(gen)
      push_node(gen, :Unquote)
      @node.construct(gen)
      gen.send(:new, 1)
    end
  end

  class Constant
    def construct(gen)
      push_node(gen, :Constant)
      gen.push_literal(@text)
      gen.send(:new, 1)
    end
  end

  class Word
    def construct(gen)
      push_node(gen, :Word)
      gen.push_literal(@text)
      gen.send(:new, 1)
    end
  end

  class Prefix
    def construct(gen)
      push_node(gen, :Prefix)
      @node.construct(gen)
      gen.push_literal(@operator)
      gen.send(:new, 2)
    end
  end

  class Postfix
    def construct(gen)
      push_node(gen, :Postfix)
      @node.construct(gen)
      gen.push_literal(@operator)
      gen.send(:new, 2)
    end
  end

  class Infix
    def construct(gen)
      push_node(gen, :Infix)
      @left.construct(gen)
      @right.construct(gen)
      gen.push_literal(@operator)
      gen.send(:new, 3)
    end
  end

  class Block
    def construct(gen)
      push_node(gen, :Block)
      @nodes.each do |node|
        node.construct(gen)
      end
      gen.make_array(@nodes.size)
      gen.send(:new, 1)
    end
  end

  class List
    def construct(gen)
      push_node(gen, :List)
      @nodes.each do |node|
        node.construct(gen)
      end
      gen.make_array(@nodes.size)
      gen.send(:new, 1)
    end
  end

  class Compose
    def construct(gen)
      push_node(gen, :Compose)
      @left.construct(gen)
      @right.construct(gen)
      gen.send(:new, 2)
    end
  end

  class Apply
    def construct(gen)
      push_node(gen, :Apply)
      @node.construct(gen)
      @arguments.each do |node|
        node.construct(gen)
      end
      gen.make_array(@arguments.size)
      gen.send(:new, 2)
    end
  end

  class StringLiteral
    def construct(gen)
      push_node(gen, :StringLiteral)
      gen.push_literal(@value)
      gen.send(:new, 1)
    end
  end
end
