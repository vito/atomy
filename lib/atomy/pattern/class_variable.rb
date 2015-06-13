require "atomy/pattern"

class Atomy::Pattern
  class ClassVariable < self
    attr_reader :scope, :name

    def initialize(scope, name)
      @scope = scope
      @name = name
    end

    def matches?(_)
      true
    end

    def assign(vars, val)
      @scope.class_variable_set(:"@@#{@name}", val)
    end
  end
end
