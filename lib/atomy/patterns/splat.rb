module Atomy::Patterns
  class Splat < Pattern
    children(:pattern)
    generate

    def target(g)
      g.push_cpath_top
      g.find_const :Object
    end

    def matches?(g)
      g.cast_array
      @pattern.matches?(g)
    end

    def deconstruct(g, locals = {})
      g.cast_array
      @pattern.deconstruct(g, locals)
    end
  end
end
