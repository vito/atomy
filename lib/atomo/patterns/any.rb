module Atomo::Patterns
  class Any < Pattern
    def target(g)
      g.push_const :Object
    end

    def match(g)
      g.pop
    end

    def locals
      []
    end
  end
end