require "atomy/pattern"

class Atomy::Pattern
  class Equality < self
    attr_reader :value

    def initialize(value)
      @value = value
    end

    def matches?(val)
      @value == val
    end

    def precludes?(other)
      other.is_a?(self.class) && @value == other.value
    end

    def target
      @value.class
    end
  end
end
