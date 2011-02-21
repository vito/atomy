module Atomo::Patterns
  class List < Pattern
    def initialize(ps)
      @patterns = ps
    end

    def target(g)
      g.push_const :Array
    end

    def match(g)
      matched = g.new_label
      mismatch = g.new_label

      g.dup # dup once for size, another for shifting
      g.dup
      g.send :size, 0
      g.push @patterns.size
      g.send :==, 1
      g.gif mismatch

      @patterns.each do |p|
        g.shift_array
        p.match(g)
      end
      g.pop

      g.goto matched

      mismatch.set!
      g.push_const :Exception
      g.push_literal "pattern mismatch"
      g.send :new, 1
      g.raise_exc

      matched.set!
    end

    def local_names
      @patterns.collect { |p| p.local_names }.flatten
    end
  end
end