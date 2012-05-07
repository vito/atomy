module Atomy::Patterns
  class Any < Pattern

    def match(g, mod, set = false, locals = {})
      g.pop
    end

    def target(g, mod)
      g.push_const :Object
    end

    def matches?(g, mod)
      g.pop
      g.push_true
    end

    def wildcard?
      true
    end
  end
end
