module Atomy::Patterns
  class Predicate < Pattern
    children :pattern
    attributes :test
    generate

    def construct(g)
      get(g)
      @pattern.construct(g)
      @test.construct(g)
      g.send(:new, 2)
    end

    def target(g)
      @pattern.target(g)
    end

    def matches?(g)
      mismatch = g.new_label
      done = g.new_label

      g.dup
      @pattern.matches?(g)
      g.gif(mismatch)

      blk = @test.new_generator(g, :predicate_pattern)
      blk.push_state Rubinius::AST::ClosedScope.new(@line)
      @test.compile(blk)
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

    def deconstruct(g, locals = {})
      @pattern.deconstruct(g, locals)
    end

    def precision
      @pattern.precision + 1
    end
  end
end
