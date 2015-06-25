require "atomy/pattern"

class Atomy::Pattern
  class InstanceVariable < self
    attr_reader :name

    def initialize(name)
      @name = name
    end

    def matches?(_)
      true
    end
  end
end
