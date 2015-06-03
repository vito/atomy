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

      @arguments.each.with_index do |pat, i|
        return false unless pat.matches?(val.locals[i])
      end

      true
    end

    def bindings(val)
      bindings = []

      if @receiver
        bindings += @receiver.bindings(val.self)
      end

      @arguments.each.with_index do |p, i|
        bindings += p.bindings(val.locals[i])
      end

      bindings
    end
  end
end
