require "atomy/pattern"

class Atomy::Pattern
  class Or < self
    attr_reader :a, :b

    def initialize(a, b)
      @a = a
      @b = b
    end

    def matches?(val)
      @a.matches?(val) || @b.matches?(val)
    end
  end
end
