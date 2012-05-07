module Atomy::Patterns
  class Default < Pattern
    children(:pattern)
    attributes(:default)

    def construct(g, mod)
      get(g)
      @pattern.construct(g, mod)
      @default.construct(g, mod)
      g.send :new, 2
      g.dup
      g.push_cpath_top
      g.find_const :Atomy
      g.send :current_module, 0
      g.send :in_context, 1
      g.pop
    end

    def target(g, mod)
      @pattern.target(g, mod)
    end

    def matches?(g, mod)
      @pattern.matches?(g, mod)
    end

    def deconstruct(g, mod, locals = {})
      defined = g.new_label

      g.dup
      g.push_undef
      g.send :equal?, 1
      g.gif defined

      g.pop
      mod.compile(g, @default)

      defined.set!
      @pattern.deconstruct(g, mod, locals)
    end

    def wildcard?
      @pattern.wildcard?
    end
  end
end

