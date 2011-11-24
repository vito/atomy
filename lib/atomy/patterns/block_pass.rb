module Atomy::Patterns
  class BlockPass < Pattern
    children(:pattern)
    generate

    def target(g)
      g.push_const :Object
    end

    def matches?(g)
      g.pop
      g.push_true
    end

    def deconstruct(g, locals = {})
      nil_block = g.new_label
      done = g.new_label

      g.dup
      g.is_nil
      g.git nil_block

      g.push_cpath_top
      g.find_const :Proc
      g.swap
      g.send :__from_block__, 1
      @pattern.deconstruct(g, locals)
      g.goto done

      nil_block.set!
      g.pop

      done.set!
    end
  end
end
