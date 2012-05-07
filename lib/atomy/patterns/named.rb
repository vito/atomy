module Atomy::Patterns
  class Named < Pattern
    children(:pattern)
    attributes(:name)

    def match(g, mod, set = false, locals = {})
      if @pattern.wildcard?
        deconstruct(g, mod, locals)
      else
        super
      end
    end

    def target(g, mod)
      @pattern.target(g, mod)
    end

    def matches?(g, mod)
      @pattern.matches?(g, mod)
    end

    def deconstruct(g, mod, locals = {})
      if locals[@name]
        local = locals[@name]
      else
        local = Atomy.assign_local(g, @name)
      end

      if @pattern.binds?
        g.dup
        @pattern.deconstruct(g, mod, locals)
      end

      local.set_bytecode(g)
      g.pop
    end

    def names
      [@name]
    end

    def binds?
      true
    end

    def wildcard?
      @pattern.wildcard?
    end

    def matches_self?(g, mod)
      @pattern.matches_self?(g, mod)
    end

    def always_matches_self?
      @pattern.always_matches_self?
    end
  end
end
