require "atomy/pattern"

class Atomy::Pattern
  class InstanceVariable < self
    attr_reader :name

    def initialize(name = nil)
      @name = name
    end

    def matches?(_)
      true
    end

    def assign(scope, val)
      scope.self.instance_variable_set(:"@#{@name}", val)
    end
  end
end
