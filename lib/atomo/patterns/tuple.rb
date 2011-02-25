module Atomo::Patterns
  class Tuple < Pattern
    def initialize(ps)
      @patterns = ps
    end

    def target(g)
      g.push_const :Array
    end

    def matches?(g)
      matched = g.new_label
      mismatch = g.new_label

      g.dup # dup once for size, another for shifting
      g.send :size, 0
      g.push @patterns.size
      g.send :==, 1
      g.gif mismatch

      @patterns.each_with_index do |p, i|
        g.dup
        g.push_int i
        g.send :[], 1
        p.matches?(g)
        g.gif mismatch
      end
      g.pop

      g.push_true
      g.goto matched

      mismatch.set!
      g.pop
      g.push_false

      matched.set!
    end

    def deconstruct(g, locals = {})
      @patterns.each_with_index do |p, i|
        g.dup
        g.push_int i
        g.send :[], 1
        p.deconstruct(g, locals)
      end
      g.pop
    end

    def local_names
      @patterns.collect { |p| p.local_names }.flatten
    end
  end
end
