module Atomo::Patterns
  class Any < Pattern
    def target(g)
      g.push_const :Object
    end

    def match(g)
      g.pop
    end

    def local_names
      []
    end

    def matches?(g)
      g.pop
      g.push_true
    end
  end
end