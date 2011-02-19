module Atomo::Pattern
  class Any
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