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

    def inline_matches?(gen)
      match = gen.new_label
      done = gen.new_label

      # [value, value]
      gen.dup

      # [bool, value]
      @a.inline_matches?(gen)

      # [value]
      gen.goto_if_true(match)

      # [bool]
      @b.inline_matches?(gen)

      # [bool]
      gen.goto(done)

      # [value]
      match.set!

      # []
      gen.pop

      # [bool]
      gen.push_true

      # [bool]
      done.set!
    end
  end
end
