require "atomy/pattern"

class Atomy::Pattern
  class Message < self
    attr_reader :receiver, :arguments

    def initialize(receiver = nil, arguments = [])
      @receiver = receiver
      @arguments = arguments
    end

    def matches?(val)
      return false unless val.kind_of?(Rubinius::VariableScope)

      if @receiver and !@receiver.matches?(val.self)
        return false
      end

      idx = 0
      @arguments.each do |pat|
        return false unless pat.matches?(val.locals[idx])
        idx += 1
      end

      true
    end

    def assign(scope, val)
      if @receiver
        @receiver.assign(scope, val.self)
      end

      idx = 0
      @arguments.each do |p|
        p.assign(scope, val.locals[idx])
        idx += 1
      end
    end

    def required_arguments
      @arguments.size
    end

    def total_arguments
      @arguments.size
    end
  end
end
