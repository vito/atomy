module Atomo::Patterns
  class Unary < Pattern
    attr_reader :receiver, :name

    def initialize(r, n)
      @receiver = r
      @name = n
    end

    def ==(b)
      b.kind_of?(Unary) and \
      @receiver == b.receiver and \
      @name == b.name
    end

    def target(g)
      g.push_const :Object
    end

    def matches?(g)
      g.pop
      g.push_true
    end

    def deconstruct(g, locals = {})
      @receiver.bytecode(g)
      g.swap
      g.send((@name + "=").to_sym, 1)
      g.pop
    end

    def local_names
      []
    end

    def bindings
      1
    end
  end
end

