require "atomy/pattern"

class Atomy::Pattern
  class Attribute < self
    attr_reader :attribute, :receiver

    def initialize(attribute, receiver)
      @attribute = attribute
      @receiver = receiver
    end

    def matches?(_)
      true
    end

    def assign(scope, val)
      @receiver.send(:"#{@attribute}=", val)
    end
  end
end
