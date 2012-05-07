module Atomy::Patterns
  class Splat < Pattern
    children(:pattern)

    def target(g, mod)
      g.push_cpath_top
      g.find_const :Object
    end

    def matches?(g, mod)
      g.cast_array
      @pattern.matches?(g, mod)
    end

    def deconstruct(g, mod, locals = {})
      g.cast_array
      @pattern.deconstruct(g, mod, locals)
    end

    def wildcard?
      @pattern.wildcard?
    end
  end
end
