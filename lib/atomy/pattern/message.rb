require "atomy/pattern"

class Atomy::Pattern
  class Message < self
    attr_reader :receiver, :arguments

    def initialize(receiver = nil, arguments = [])
      @receiver = receiver
      @arguments = arguments
    end

    def matches?(gen)
      done = gen.new_label
      mismatch = gen.new_label

      if @receiver && !@receiver.wildcard?
        gen.push_self
        @receiver.matches?(gen)
        gen.gif(mismatch)
      end

      gen.dup
      gen.send(:size, 0)
      gen.push_int(@arguments.size)
      gen.send(:==, 1)
      gen.gif(mismatch)

      @arguments.each do |arg|
        gen.shift_array

        if arg.wildcard?
          gen.pop
        else
          arg.matches?(gen)
          gen.gif(mismatch)
        end
      end

      gen.pop
      gen.push_true
      gen.goto done

      mismatch.set!
      gen.pop # pop args
      gen.push_false

      done.set!
    end

    def deconstruct(gen)
      if @receiver && @receiver.binds?
        gen.push_self
        @receiver.deconstruct(gen)
        gen.pop
      end

      return unless @arguments.any?(&:binds?)

      gen.dup

      @arguments.each do |arg|
        gen.shift_array
        arg.deconstruct(gen)
        gen.pop
      end

      gen.pop
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

    def binds?
      @receiver.binds? || @arguments.any?(&:binds?)
    end
  end
end
