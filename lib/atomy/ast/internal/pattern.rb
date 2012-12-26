module Atomy::AST
  class Pattern < Node
    attributes :pattern

    def construct(g, mod, d = nil)
      get(g)
      g.send :new, 0

      g.dup
      g.push_int(@line)
      g.send :line=, 1
      g.pop

      g.dup
      @pattern.construct(g, mod)
      g.send :pattern=, 1
      g.pop
    end

    def bytecode(g, mod)
      @pattern.construct(g, mod)
    end

    def to_pattern
      @pattern
    end
  end
end
