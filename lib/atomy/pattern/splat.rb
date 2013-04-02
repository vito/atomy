require "atomy/pattern"

class Atomy::Pattern
  class Splat < self
    attr_reader :pattern

    def initialize(pattern)
      @pattern = pattern
    end

    def matches?(gen)
      @pattern.matches?(gen)
    end

    def deconstruct(gen)
      @pattern.deconstruct(gen)
    end

    def binds?
      @pattern.binds?
    end

    def precludes?(other)
      other.is_a?(self.class) && @pattern.precludes?(other.pattern)
    end
  end
end

