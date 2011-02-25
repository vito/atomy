module Atomo::Patterns
  class Any < Pattern
    def target(g)
      g.push_const :Object
    end

    def matches?(g)
      g.pop
      g.push_true
    end
  end
end