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

      # don't match if args aren't same count
      #
      # TODO: handle splats
      #
      # TODO: won't work for methods with branches that have varying arg counts
      return false unless val.locals.size == @arguments.size

      idx = 0
      @arguments.each do |pat|
        return false unless pat.matches?(val.locals[idx])
        idx += 1
      end

      true
    end

    def bindings(val)
      bindings = []

      if @receiver
        bindings += @receiver.bindings(val.self)
      end

      idx = 0
      @arguments.each do |p|
        bindings += p.bindings(val.locals[idx])
        idx += 1
      end

      bindings
    end
  end
end
