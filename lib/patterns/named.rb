module Atomy::Patterns
  class Named < Pattern
    attr_reader :name, :pattern

    def initialize(n, p)
      @name = n
      @pattern = p
    end

    def construct(g)
      get(g)
      g.push_literal @name
      @pattern.construct(g)
      g.send :new, 2
    end

    def ==(b)
      b.kind_of?(Named) and \
      @name == b.name and \
      @pattern == b.pattern
    end

    def target(g)
      @pattern.target(g)
    end

    def matches?(g)
      @pattern.matches?(g)
    end

    def deconstruct(g, locals = {})
      if locals[@name]
        local = locals[@name]
      else
        local = Atomy.assign_local(g, @name)
      end

      if @pattern.bindings > 0
        g.dup
        @pattern.deconstruct(g, locals)
      end

      local.set_bytecode(g)
      g.pop
    end

    def local_names
      [@name] + @pattern.local_names
    end

    def bindings
      1 + @pattern.bindings
    end
  end
end
