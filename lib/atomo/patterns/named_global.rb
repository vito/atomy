module Atomo::Patterns
  class NamedGlobal < Pattern
    attr_reader :name

    def initialize(n)
      @name = n
    end

    def ==(b)
      b.kind_of?(NamedGlobal) and \
      @name == b.name
    end

    def target(g)
      g.push_const :Object
    end

    def matches?(g)
      g.pop
      g.push_true
    end

    def deconstruct(g, locals = {})
      Rubinius::AST::GlobalVariableAssignment.new(0, @name, nil).bytecode(g)
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
