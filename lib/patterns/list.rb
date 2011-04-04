module Atomy::Patterns
  class List < Pattern
    attr_reader :patterns

    def initialize(ps)
      @patterns = ps
    end

    def construct(g)
      get(g)
      @patterns.each do |p|
        p.construct(g)
      end
      g.make_array @patterns.size
      g.send :new, 1
    end

    def ==(b)
      b.kind_of?(List) and \
      @patterns == b.patterns
    end

    def target(g)
      g.push_const :Array
    end

    def matches?(g)
      matched = g.new_label
      mismatch = g.new_label

      g.dup
      g.push_cpath_top
      g.find_const :Array
      g.swap
      g.kind_of
      g.gif mismatch

      g.dup
      g.send :size, 0
      g.push @patterns.size
      g.send :==, 1
      g.gif mismatch

      @patterns.each do |p|
        g.shift_array
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
      @patterns.each do |p|
        g.shift_array
        p.deconstruct(g, locals)
      end
      g.pop
    end

    def local_names
      @patterns.collect { |p| p.local_names }.flatten
    end

    def bindings
      @patterns.reduce(0) { |a, p| p.bindings + a }
    end
  end
end
