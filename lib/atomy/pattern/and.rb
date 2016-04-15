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

    def inline_matches?(gen)
      mismatch = gen.new_label
      done = gen.new_label

      # [value, value]
      gen.dup

      # [bool, value]
      @a.inline_matches?(gen)

      # [value]
      gen.goto_if_false(mismatch)

      # [bool]
      @b.inline_matches?(gen)

      # [bool]
      gen.goto(done)

      # [value]
      mismatch.set!

      # []
      gen.pop

      # [bool]
      gen.push_false

      # [bool]
      done.set!
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
