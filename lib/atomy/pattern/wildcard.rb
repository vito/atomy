require "atomy/pattern"

class Atomy::Pattern
  class Wildcard < self
    def matches?(_)
      true
    end

    def inline_matches?(gen)
      gen.pop
      gen.push_true
    end

    def target
      Object
    end
  end
end
