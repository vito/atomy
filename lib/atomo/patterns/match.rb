module Atomo::Pattern
  class Match
    def initialize(x)
      @value = x
    end

    def target(g)
      case @value
      when :true
        g.push_const :TrueClass
      when :false
        g.push_const :FalseClass
      when :nil
        g.push_const :NilClass
      when :self
        g.push_self
        g.send :class, 0
      else
        g.push_const @value.class.name.to_sym
      end
    end

    def match(g)
      matched = g.new_label
      mismatch = g.new_label

      g.push @value
      g.send :==, 1
      g.gif mismatch

      g.push @value
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