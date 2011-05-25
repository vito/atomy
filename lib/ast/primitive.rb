module Atomy::AST
  class Primitive < Node
    attributes :value
    generate

    def bytecode(g)
      pos(g)
      g.push @value
    end
  end
end
