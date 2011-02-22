module Atomo::Patterns
  class Constant < Pattern
    def initialize(name)
      @name = name
    end

    def target(g)
      g.push_const @name.to_sym
    end

    def matches?(g)
      g.push_const @name.to_sym
      g.swap
      g.kind_of
    end

    def construct(g)
      g.push_const :Atomo
      g.find_const :Patterns
      g.find_const :Constant
      g.push_literal @name
      g.send :new, 1
    end

    def local_names
      []
    end
  end
end