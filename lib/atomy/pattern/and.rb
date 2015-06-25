require "atomy/pattern"

class Atomy::Pattern
  class And < self
    attr_reader :a, :b

    def initialize(a, b)
      @a = a
      @b = b
    end

    def matches?(val)
      @a.matches?(val) && @b.matches?(val)
    end

    def assign(gen)
      @a.assign(gen)
      @b.assign(gen)
    end

    def target
      a = @a.target
      b = @b.target
      a < b ? a : b
    end
  end
end
