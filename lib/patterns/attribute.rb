module Atomy::Patterns
  class Attribute < Pattern
    attr_reader :receiver, :name, :arguments

    def initialize(r, n, as = [])
      @receiver = r.prepare_all
      @name = n
      @arguments = as.collect(&:prepare_all)
    end

    def construct(g)
      get(g)
      @receiver.construct(g, nil)
      g.push_literal @name
      @arguments.each do |a|
        a.construct(g)
      end
      g.make_array @arguments.size
      g.send :new, 3
    end

    def ==(b)
      b.kind_of?(Attribute) and \
      @receiver == b.receiver and \
      @name == b.name and \
      @arguments == b.arguments
    end

    def target(g)
      raise "tried to get target of Attribute pattern: #{self.inspect}"
    end

    def matches?(g)
      g.pop
      g.push_true
    end

    def deconstruct(g, locals = {})
      @receiver.compile(g)
      g.swap
      @arguments.each do |a|
        a.compile(g)
        g.swap
      end
      g.send((@name + "=").to_sym, 1 + @arguments.size)
      g.pop
    end

    def local_names
      []
    end

    def bindings
      1
    end

    def wildcard?
      true
    end
  end
end

