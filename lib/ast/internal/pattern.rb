module Atomy::AST
  class Pattern < Node
    attributes :pattern
    generate

    def construct(g)
      get(g)
      g.push_int(@line)
      @pattern.construct(g)
      g.send :new, 2
    end

    def bytecode(g)
      @pattern.construct(g)
    end
  end
end
