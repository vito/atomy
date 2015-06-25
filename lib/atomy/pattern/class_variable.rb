require "atomy/pattern"

class Atomy::Pattern
  class ClassVariable < self
    attr_reader :name

    def initialize(name)
      @name = name
    end

    def matches?(_)
      true
    end
  end
end
