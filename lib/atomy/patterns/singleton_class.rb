module Atomy::Patterns
  class SingletonClass < Pattern
    attributes(:body)
    generate

    def construct(g, mod)
      get(g)
      @body.construct(g, mod)
      g.send :new, 1
      g.dup
      g.push_cpath_top
      g.find_const :Atomy
      g.send :current_module, 0
      g.send :in_context, 1
      g.pop
    end

    def target(g, mod)
      mod.compile(g, @body)
      g.send :singleton_class, 0
    end

    def matches?(g, mod)
      g.pop
      g.push_true
    end

    def wildcard?
      true
    end
  end
end
