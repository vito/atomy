module Atomy::Patterns
  class SingletonClass < Pattern
    attributes(:body)
    generate

    def target(g)
      @body.compile(g)
      g.send :call, 0
      g.send :singleton_class, 0
    end

    def matches?(g)
      g.pop
      g.push_true
    end

    def wildcard?
      true
    end
  end
end
