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
      return false unless val.locals.size == @arguments.size

      @arguments.each.with_index do |pat, i|
        return false unless pat.matches?(val.locals[i])
      end

      true
    end

    def precludes?(other)
      return false unless other.is_a?(self.class)

      return false unless !@receiver || @receiver.precludes?(other.receiver)

      return false unless @arguments.size == other.arguments.size

      @arguments.each.with_index do |arg, i|
        return false unless arg.precludes?(other.arguments[i])
      end

      true
    end

    def locals
      locals = []

      locals += @receiver.locals if @receiver

      @arguments.each do |p|
        locals += p.locals
      end

      locals
    end

    def assign(scope, val)
      if @receiver
        @receiver.assign(scope, val.self)
      end

      @arguments.each.with_index do |p, i|
        p.assign(scope, val.locals[i])
      end
    end
  end
end
