require "atomy/pattern"

class Atomy::Pattern
  class Attribute < self
    attr_reader :receiver, :arguments

    def initialize(receiver, arguments = [])
      @receiver = receiver
      @arguments = arguments
    end

    def matches?(_)
      true
    end
  end
end
