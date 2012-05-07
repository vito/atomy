module Atomy::AST
  class Literal < Node
    attributes :value

    def bytecode(g, mod)
      pos(g)
      g.push_literal @value
    end

    # don't dup our value
    def copy
      dup
    end
  end

  class StringLiteral < Literal
    attributes :value, :raw?

    def bytecode(g, mod)
      super
      g.string_dup
    end
  end
end
