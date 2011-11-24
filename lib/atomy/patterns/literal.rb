module Atomy::Patterns
  class Literal < Pattern
    attributes(:value)
    generate

    def target(g)
      Atomy.const_from_string(g, @value.class.name)
    end

    def matches?(g)
      g.push_literal @value
      g.send :==, 1
    end
  end
end
