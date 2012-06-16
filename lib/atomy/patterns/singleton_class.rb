module Atomy::Patterns
  class SingletonClass < Constant
    attributes(:body, :value?)

    def construct(g, mod)
      get(g)
      @body.construct(g, mod)
      target(g, mod)
      g.send :new, 2
      g.push_cpath_top
      g.find_const :Atomy
      g.send :current_module, 0
      g.send :in_context, 1
    end

    def target(g, mod)
      if @value
        g.push_literal @value
      else
        mod.compile(g, @body)
        g.send :singleton_class, 0
      end
    end

    def assign(g, mod, e, set = false)
      mod.compile(g, e)
      g.dup
      match(g, mod, set)
    end
  end
end
