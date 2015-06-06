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

    def assign(scope, val)
      if @a.matches?(val)
        @a.assign(scope, val)
      else
        @b.assign(scope, val)
      end
    end
  end
end
