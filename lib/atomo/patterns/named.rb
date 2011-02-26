module Atomo::Patterns
  class Named < Pattern
    def initialize(n, p)
      @name = n
      @pattern = p
      @variable = nil
    end

    attr_accessor :name, :variable

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

      if @pattern.locals > 0
        g.dup
        @pattern.deconstruct(g, locals)
      end

      @variable.set_bytecode(g)
      g.pop
    end

    def local_names
      [@name]
    end
  end
end