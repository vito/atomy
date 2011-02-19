module Atomo::Pattern
  class Constant
    def initialize(name)
      @name = name
    end

    def target(g)
      g.push_const @name.to_sym
    end

    def match(g)
      matched = g.new_label
      mismatch = g.new_label

      g.dup
      g.push_const @name.to_sym
      g.swap
      g.kind_of
      g.gif mismatch

      g.goto matched

      mismatch.set!
      g.push_const :Exception
      g.push_literal "pattern mismatch"
      g.send :new, 1
      g.raise_exc

      matched.set!
    end

    def locals
      []
    end
  end
end