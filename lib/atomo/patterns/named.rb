module Atomo::Patterns
  class Named < Pattern
    def initialize(n, p)
      @name = n
      @pattern = p
    end

    def target(g)
      @pattern.target(g)
    end

    def match(g)
      var = g.state.scope.new_local @name
      g.dup
      @pattern.match(g)
      g.set_local var.slot
      g.pop
    end

    def local_names
      [@name]
    end
  end
end