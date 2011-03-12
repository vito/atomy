module Atomo::Patterns
  class Metaclass < Pattern
    attr_reader :body

    def initialize(body, id = nil)
      @body = body
      @id = id
    end

    def construct(g)
      get(g)
      @body.construct(g, nil)
      target(g)
      g.send(:object_id, 0)
      g.send(:new, 2)
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
      if @id
        g.send(:metaclass, 0)
        g.send(:object_id, 0)
        g.push_int(@id)
        g.send(:==, 1)
      else
        g.pop
        g.push_true
      end
    end
  end
end
