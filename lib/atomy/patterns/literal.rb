module Atomy::Patterns
  class Literal < Pattern
    attributes(:value)

    def target(g, mod)
      Atomy.const_from_string(g, @value.class.name)
    end

    def matches?(g, mod)
      g.push_literal @value
      g.send :==, 1
    end
  end
end
