require "atomy/pattern"

class Atomy::Pattern
  class Splat < self
    attr_reader :pattern

    def initialize(pattern)
      @pattern = pattern
    end

    def matches?(val)
      @pattern.matches?(val)
    end
  end
end
