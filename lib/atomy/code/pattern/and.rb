require "atomy/code/pattern"

require "atomy/node/meta"


class Atomy::Code::Pattern
  class And < self
    def initialize(a, b)
      @a = a
      @b = b
    end

    def bytecode(gen, mod)
      gen.push_cpath_top
      gen.find_const(:Atomy)
      gen.find_const(:Pattern)
      gen.find_const(:And)
      mod.compile(gen, @a)
      mod.compile(gen, @b)
      gen.send(:new, 2)
    end

    def assign(gen)
      # [value, pattern, value, pattern]
      gen.dup_many(2)

      # [pattern, value, value, pattern]
      gen.swap

      # [a pattern, value, value, pattern]
      gen.send(:a, 0)

      # [value, a pattern, value, pattern]
      gen.swap

      # [value, a pattern, value, pattern]
      @a.assign(gen)

      # [value, pattern]
      gen.pop_many(2)

      # [value, pattern, value, pattern]
      gen.dup_many(2)

      # [pattern, value, value, pattern]
      gen.swap

      # [b pattern, value, value, pattern]
      gen.send(:b, 0)

      # [value, b pattern, value, pattern]
      gen.swap

      # [value, b pattern, value, pattern]
      @b.assign(gen)

      # [value, pattern]
      gen.pop_many(2)
    end
  end
end
