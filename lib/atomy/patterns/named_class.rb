module Atomy::Patterns
  class NamedClass < Pattern
    attributes(:identifier)
    generate

    def name
      :"@@#{@identifier}"
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

    def bound
      1
    end

    def wildcard?
      true
    end
  end
end
