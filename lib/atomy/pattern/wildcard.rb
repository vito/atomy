require "atomy/pattern"

class Atomy::Pattern
  class Wildcard < self
    def matches?(_)
      true
    end
  end
end
