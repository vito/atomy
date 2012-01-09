module Atomy::Patterns
  class Constant < Pattern
    attributes(:constant, :value?)
    generate

    def construct(g)
      get(g)
      @constant.construct(g)
      if @value
        g.push_literal @value
      else
        # TODO: spec compile vs. bytecode
        @constant.bytecode(g)
      end
      g.send :new, 2
    end

    def target(g)
      if @value
        g.push_literal @value
      else
        @constant.bytecode(g)
      end
    end

    def matches?(g)
      target(g)
      g.swap
      g.kind_of
    end

    def assign(g, e, set = false)
      @constant.assign(g, e)
    end

    def always_matches_self?
      true
    end
  end
end
