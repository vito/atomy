require "atomy/pattern"

class Atomy::Pattern
  class Index < self
    attr_reader :receiver, :arguments

    def initialize(receiver, arguments)
      @receiver = receiver
      @arguments = arguments
    end

    def matches?(_)
      true
    end

    def assign(scope, val)
      @receiver[*@arguments] = val
    end
  end
end
