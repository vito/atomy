module Atomy::Patterns
  class List < Pattern
    attr_reader :patterns

    def initialize(ps)
      @patterns = ps.to_a
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
      g.push_cpath_top
      g.find_const :Hamster
      g.find_const :List
    end

    def matches?(g)
      matched = g.new_label
      mismatch = g.new_label

      has_splat = @patterns.any? { |p| p.is_a?(Splat) }

      unless has_splat
        g.dup
        g.push_literal :size
        g.send :respond_to?, 1
        g.gif mismatch
      end

      g.dup
      g.push_literal :[]
      g.send :respond_to?, 1
      g.gif mismatch

      unless has_splat
        g.dup
        g.send :size, 0
        g.push @patterns.size
        g.send :==, 1
        g.gif mismatch
      end

      @patterns.each_with_index do |p, i|
        g.dup
        if p.is_a?(Splat)
          g.push_int i
          g.send :drop, 1
        else
          g.push_int i
          g.send :[], 1
        end
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
        if p.is_a?(Splat)
          g.push_int i
          g.send :drop, 1
        else
          g.push_int i
          g.send :[], 1
        end
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
