module Atomy::Patterns
  class NamedClass < Pattern
    attr_reader :identifier

    def initialize(n)
      @identifier = n
    end

    def name
      ("@@" + @identifier).to_sym
    end

    def construct(g)
      get(g)
      g.push_literal @identifier
      g.send :new, 1
    end

    def ==(b)
      b.kind_of?(NamedClass) and \
      @identifier == b.identifier
    end

    def target(g)
      g.push_const :Object
    end

    def matches?(g)
      g.pop
      g.push_true
    end

    def deconstruct(g, locals = {})
      Rubinius::AST::ClassVariableAssignment.new(0, name, nil).bytecode(g)
      g.pop
    end

    def local_names
      []
    end

    def bindings
      1
    end
  end
end
