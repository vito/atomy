require "atomy/node/constructable"

module Atomy
  class Pattern
    attr_accessor :node

    def match(gen, mod)
      return if wildcard? && !binds?

      unless wildcard?
        gen.dup

        done = gen.new_label
        mismatch = gen.new_label

        matches?(gen, mod)
        gen.gif(mismatch)
      end

      deconstruct(gen, mod)

      unless wildcard?
        gen.goto(done)

        mismatch.set!
        gen.dup
        gen.push_cpath_top
        gen.find_const(:Atomy)
        gen.find_const(:PatternMismatch)
        gen.swap
        @node.construct(gen)
        gen.swap
        gen.send(:new, 2)
        gen.raise_exc

        done.set!
      end
    end

    def binds?
      false
    end

    def wildcard?
      false
    end

    def matches?(gen)
      raise NotImplementedError
    end

    def deconstruct(gen, mod)
    end

    def assignment_local(gen, name, set = false)
      var = gen.state.scope.search_local(name)

      if var && (set || var.depth == 0)
        var
      else
        gen.state.scope.new_local(name).nested_reference
      end
    end
  end
end
