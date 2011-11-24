module Atomy::Patterns
  class Splat < Pattern
    children(:pattern)
    generate

    def target(g)
      g.push_const :Object
    end

    def matches?(g)
      @pattern.matches?(g)
    end

    def deconstruct(g, locals = {})
      g.cast_array
      @pattern.deconstruct(g, locals)
    end
  end
end
