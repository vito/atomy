require "atomy/pattern"

class Atomy::Pattern
  class Wildcard < self
    attr_reader :name

    def initialize(name = nil)
      @name = name
    end

    def matches?(_)
      true
    end

    def bindings(val)
      if @name
        [val]
      else
        []
      end
    end
  end
end
