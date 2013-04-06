require "atomy/pattern"

class Atomy::Pattern
  class And < self
    attr_reader :a, :b

    def initialize(a, b)
      @a = a
      @b = b
    end

    def matches?(gen)
      mismatch = gen.new_label
      done = gen.new_label

      gen.dup

      @a.matches?(gen)
      gen.gif(mismatch)

      @b.matches?(gen)
      gen.goto(done)

      mismatch.set!
      gen.pop
      gen.push_false

      done.set!
    end

    def deconstruct(gen)
      @a.deconstruct(gen)
      @b.deconstruct(gen)
    end

    def precludes?(other)
      @a.precludes?(other) && @b.precludes?(other)
    end

    def wildcard?
      @a.wildcard? && @b.wildcard?
    end

    def binds?
      @a.binds? || @b.binds?
    end
  end
end
