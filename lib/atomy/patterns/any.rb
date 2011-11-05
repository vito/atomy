module Atomy::Patterns
  class Any < Pattern
    def construct(g)
      get(g)
      g.send :new, 0
    end

    def ==(b)
      b.kind_of?(Any)
    end

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
