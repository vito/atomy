module Atomo::Patterns
  class Named < Pattern
    attr_reader :name, :pattern
    attr_accessor :variable

    def initialize(n, p)
      @name = n
      @pattern = p
      @variable = nil
    end

    def construct(g)
      get(g)
      g.push_literal @name
      @pattern.construct(g)
      g.send :new, 2
    end

    def ==(b)
      b.kind_of?(Named) and \
      @name == b.name and \
      @pattern == b.pattern
    end

    def target(g)
      @pattern.target(g)
    end

    def matches?(g)
      @pattern.matches?(g)
    end

    def deconstruct(g, locals = {})
      unless @variable
        if locals[@name]
          @variable = locals[@name]
        else
          g.state.scope.assign_local_reference self
        end
      end

      if @pattern.bindings > 0
        g.dup
        @pattern.deconstruct(g, locals)
      end

      @variable.set_bytecode(g)
      g.pop
    end

    def local_names
      [@name]
    end

    def bindings
      1
    end
  end
end
