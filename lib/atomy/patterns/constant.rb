module Atomy::Patterns
  class Constant < Pattern
    attributes(:constant, :value?)

    def construct(g, mod)
      get(g)
      @constant.construct(g, mod)
      if @value
        g.push_literal @value
      else
        @constant.bytecode(g, mod)
      end
      g.send :new, 2
      g.dup
      g.push_cpath_top
      g.find_const :Atomy
      g.send :current_module, 0
      g.send :in_context, 1
      g.pop
    end

    def target(g, mod)
      if @value
        g.push_literal @value
      else
        @constant.bytecode(g, mod)
      end
    end

    def matches?(g, mod)
      target(g, mod)
      g.swap
      g.kind_of
    end

    def assign(g, mod, e, set = false)
      @constant.assign(g, mod, e)
    end

    def always_matches_self?
      true
    end
  end
end
