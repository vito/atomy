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
      # don't use send; Generator implements #send, other things might too.
      @receiver.__send__(:"#{@attribute}=", val)
    end
  end
end
