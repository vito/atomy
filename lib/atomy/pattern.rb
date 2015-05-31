require "atomy/node/constructable"
require "rubinius/ast"

module Atomy
  class Pattern
    attr_accessor :from_node

    def ===(v)
      singleton_class.dynamic_method(:===) do |gen|
        gen.push_state CodeTools::AST::ClosedScope.new(0)
        gen.total_args = gen.required_args = gen.local_count = 1
        gen.push_local(0)

        matches?(gen)

        gen.ret
      end

      __send__ :===, v
    end

    def match(gen)
      return if wildcard? && !binds?

      unless wildcard?
        gen.dup

        done = gen.new_label
        mismatch = gen.new_label

        matches?(gen)
        gen.gif(mismatch)
      end

      deconstruct(gen)

      unless wildcard?
        gen.goto(done)

        mismatch.set!
        gen.dup
        gen.push_cpath_top
        gen.find_const(:Atomy)
        gen.find_const(:PatternMismatch)
        gen.swap
        @from_node.construct(gen)
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

    def always_matches_self?
      wildcard?
    end

    def inlineable?
      false
    end

    def matches?(gen)
      raise NotImplementedError
    end

    def deconstruct(gen)
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
