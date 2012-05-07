module Atomy::AST
  class Pattern < Node
    attributes :pattern

    def construct(g, mod, d = nil)
      get(g)
      g.push_int(@line)
      @pattern.construct(g, mod)
      g.send :new, 2
    end

    def bytecode(g, mod)
      @pattern.construct(g, mod)
    end

    def to_pattern
      @pattern
    end
  end
end
