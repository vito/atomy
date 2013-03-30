require "atomy/pattern"

class Atomy::Pattern
  class Equality < self
    attr_reader :value

    def initialize(value)
      @value = value
    end

    def matches?(gen, mod)
      case @value
      when Fixnum
        gen.push_int(@value)
      when true
        gen.push_true
      when false
        gen.push_false
      when nil
        gen.push_nil
      when String
        gen.push_literal(@value)
        gen.string_dup
      when Atomy::Grammar::AST::Node
        @value.construct(gen)
      else
        raise "don't know how to match #{value} for equality"
      end

      gen.send(:==, 1)
    end

    def precludes?(other)
      other.is_a?(self.class) && @value == other.value
    end
  end
end
