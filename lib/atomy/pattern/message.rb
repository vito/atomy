require "atomy/pattern"

class Atomy::Pattern
  class Message < self
    attr_reader :receiver, :arguments

    def initialize(receiver = nil, arguments = [])
      @receiver = receiver
      @arguments = arguments
    end

    # note: this does not pop anything from the stack, which is pretty
    # inconsistent.
    def matches?(gen)
      done = gen.new_label
      mismatch = gen.new_label

      if @receiver && !@receiver.always_matches_self?
        gen.push_self
        @receiver.matches?(gen)
        gen.gif(mismatch)
      end

      gen.passed_arg(@arguments.size - 1)
      gen.gif(mismatch)

      # don't match extra args
      gen.passed_arg(@arguments.size)
      gen.git(mismatch)

      @arguments.each.with_index do |arg, i|
        next if arg.wildcard?

        gen.push_local(i)
        arg.matches?(gen)
        gen.gif(mismatch)
      end

      gen.push_true
      gen.goto done

      mismatch.set!
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

      @arguments.each.with_index do |arg, i|
        gen.push_local(i)
        arg.deconstruct(gen)
      end
    end

    def inlineable?
      (!@receiver || @receiver.always_matches_self? || @receiver.inlineable?) && \
        @arguments.all?(&:inlineable?)
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
