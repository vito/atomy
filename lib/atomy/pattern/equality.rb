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

    def inline_matches?(gen)
      push_value(gen)
      gen.swap
      gen.send(:==, 1)
    end

    def target
      @value.class
    end

    private

    def push_value(gen)
      case @value
      when true
        gen.push_true
      when false
        gen.push_false
      when nil
        gen.push_nil
      when Integer
        gen.push_int(@value)
      else
        gen.push_literal(@value)
      end
    end
  end
end
