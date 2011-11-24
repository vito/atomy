module Atomy::Patterns
  class Any < Pattern
    generate

    def match(g, set = false, locals = {})
      g.pop
    end

    def target(g)
      g.push_const :Object
    end

    def matches?(g)
      g.pop
      g.push_true
    end

    def wildcard?
      true
    end
  end
end
