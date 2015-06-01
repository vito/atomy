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

    def precludes?(other)
      @a.precludes?(other) && @b.precludes?(other)
    end

    def locals
      @a.locals + @b.locals
    end

    def assign(scope, val)
      @a.assign(scope, val)
      @b.assign(scope, val)
    end
  end
end
