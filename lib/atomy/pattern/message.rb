require "atomy/pattern"

class Atomy::Pattern
  class Message < self
    attr_reader :receiver, :arguments

    def initialize(receiver = nil, arguments = [])
      @receiver = receiver
      @arguments = arguments
    end

    def required_arguments
      @arguments.size
    end

    def total_arguments
      @arguments.size
    end
  end
end
