module Atomy::Patterns
  class Attribute < Pattern
    attributes(:receiver, :name, :arguments)
    generate

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

    def target(g)
      g.push_cpath_top
      g.find_const :Object
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
      g.send(:"#{@name}=", 1 + @arguments.size)
      g.pop
    end

    def binds?
      true
    end

    def wildcard?
      true
    end
  end
end

