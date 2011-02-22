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

    def construct(g)
      g.push_const :Atomo
      g.find_const :Patterns
      g.find_const :Any
      g.send :new, 0
    end
  end
end