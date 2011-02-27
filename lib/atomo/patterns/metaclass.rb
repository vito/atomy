module Atomo::Patterns
  class Metaclass < Pattern
    attr_reader :body

    def initialize(body)
      @body = body
    end

    def ==(b)
      b.kind_of?(Metaclass) and \
      @body == b.body
    end

    def target(g)
      @body.bytecode(g)
      g.send :call, 0
      g.send :metaclass, 0
    end

    def matches?(g)
      g.pop # TODO?
      g.push_true
    end
  end
end
