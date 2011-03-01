module Atomo::Patterns
  class Variadic < Pattern
    attr_accessor :pattern

    def initialize(p)
      @pattern = p
    end

    def ==(b)
      b.kind_of?(Variadic) and \
      @pattern == b.pattern
    end

    def target(g)
      g.push_const :Object
    end

    def matches?(g)
      g.pop
      g.push_true
    end

    def deconstruct(g, locals = {})
      singleton = g.new_label
      done = g.new_label

      g.dup
      g.push_const :Array
      g.swap
      g.instance_of
      g.git singleton

      g.cast_array
      g.goto done

      singleton.set!
      g.make_array 1

      done.set!
      @pattern.deconstruct(g, locals)
    end

    def local_names
      @pattern.local_names
    end

    def bindings
      @pattern.bindings
    end
  end
end
