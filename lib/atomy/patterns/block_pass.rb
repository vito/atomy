module Atomy::Patterns
  class BlockPass < Pattern
    children(:pattern)

    def target(g, mod)
      g.push_const :Object
    end

    def matches?(g, mod)
      g.pop
      g.push_true
    end

    def deconstruct(g, mod, locals = {})
      match = g.new_label

      g.dup
      g.is_nil
      g.git match

      g.push_cpath_top
      g.find_const :Proc
      g.swap
      g.send :__from_block__, 1

      match.set!
      @pattern.deconstruct(g, mod, locals)
    end

    def wildcard?
      @pattern.wildcard?
    end
  end
end
