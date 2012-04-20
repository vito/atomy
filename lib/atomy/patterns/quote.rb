module Atomy::Patterns
  class Quote < Pattern
    attributes(:expression)
    generate

    def construct(g, mod)
      get(g)
      @expression.construct(g, mod)
      g.send :new, 1
      g.dup
      g.push_cpath_top
      g.find_const :Atomy
      g.send :current_module, 0
      g.send :in_context, 1
      g.pop
    end

    def target(g, mod)
      @expression.get(g)
    end

    def matches?(g, mod)
      @expression.construct(g, mod)
      g.send :==, 1
    end
  end
end
