module Atomy::Patterns
  class Predicate < Pattern
    children :pattern
    attributes :test

    def construct(g, mod)
      get(g)
      @pattern.construct(g, mod)
      @test.construct(g, mod)
      g.send(:new, 2)
      g.push_cpath_top
      g.find_const :Atomy
      g.send :current_module, 0
      g.send :in_context, 1
    end

    def target(g, mod)
      @pattern.target(g, mod)
    end

    def matches?(g, mod)
      mismatch = g.new_label
      done = g.new_label

      g.dup
      @pattern.matches?(g, mod)
      g.gif(mismatch)

      blk = @test.new_generator(g, :predicate_pattern)
      blk.push_state Rubinius::AST::ClosedScope.new(@line)
      mod.compile(blk, @test)
      blk.ret
      blk.close
      blk.pop_state

      g.create_block blk
      g.swap
      g.send :call_on_instance, 1
      g.goto(done)

      mismatch.set!
      g.pop
      g.push_false

      done.set!
    end

    def deconstruct(g, mod, locals = {})
      @pattern.deconstruct(g, mod, locals)
    end

    def precision
      @pattern.precision + 1
    end
  end
end
