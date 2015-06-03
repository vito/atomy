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

    def bindings(val)
      @a.bindings(val) + @b.bindings(val)
    end
  end
end
