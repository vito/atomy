require "atomy/pattern"

class Atomy::Pattern
  class Wildcard < self
    attr_reader :name

    def initialize(name = nil)
      @name = name
    end

    def matches?(gen, mod)
      gen.pop
      gen.push_true
    end

    def deconstruct(gen, mod)
      return unless @name
      assignment_local(gen, @name).set_bytecode(gen)
    end

    def wildcard?
      true
    end

    def binds?
      !!@name
    end
  end
end
