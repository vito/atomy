require "atomy/code/pattern"

require "atomy/node/meta"


class Atomy::Code::Pattern
  class Splat < self
    def initialize(pattern)
      @pattern = pattern
    end

    def bytecode(gen, mod)
      gen.push_cpath_top
      gen.find_const(:Atomy)
      gen.find_const(:Pattern)
      gen.find_const(:Splat)
      mod.compile(gen, @pattern)
      gen.send(:new, 1)
    end

    def assign(gen)
      @pattern.assign(gen)
    end

    def splat?
      true
    end
  end
end
