module Atomo::Pattern
  class Variadic
    attr_accessor :pattern

    def initialize(p)
      @pattern = p
    end

    def target(g)
      g.push_const :Object
    end

    def match(g)
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
      @pattern.match(g)
    end

    def locals
      @pattern.locals
    end
  end
end