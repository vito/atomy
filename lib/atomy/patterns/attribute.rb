module Atomy::Patterns
  class Attribute < Pattern
    attributes(:receiver, :name, :arguments)

    def construct(g, mod)
      get(g)
      @receiver.construct(g, mod)
      g.push_literal @name
      @arguments.each do |a|
        a.construct(g, mod)
      end
      g.make_array @arguments.size
      g.send :new, 3
      g.dup
      g.push_cpath_top
      g.find_const :Atomy
      g.send :current_module, 0
      g.send :in_context, 1
      g.pop
    end

    def target(g, mod)
      g.push_cpath_top
      g.find_const :Object
    end

    def matches?(g, mod)
      g.pop
      g.push_true
    end

    def deconstruct(g, mod, locals = {})
      mod.compile(g, @receiver)
      g.swap
      @arguments.each do |a|
        mod.compile(g, a)
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

