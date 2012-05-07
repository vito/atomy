module Atomy::Patterns
  class NamedGlobal < Pattern
    attributes(:identifier)

    def name
      :"$#{@identifier}"
    end

    def target(g, mod)
      g.push_const :Object
    end

    def matches?(g, mod)
      g.pop
      g.push_true
    end

    def deconstruct(g, mod, locals = {})
      Rubinius::AST::GlobalVariableAssignment.new(0, name, nil).bytecode(g)
      g.pop
    end

    def binds?
      true
    end

    def wildcard?
      true
    end
  end
end
