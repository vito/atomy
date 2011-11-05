module Atomy::Patterns
  class Match < Pattern
    attr_reader :value

    def initialize(x)
      @value = x
    end

    def construct(g)
      get(g)
      g.push_literal @value
      g.send :new, 1
    end

    def ==(b)
      b.kind_of?(Match) and \
      @value == b.value
    end

    def target(g)
      case @value
      when :true
        g.push_const :TrueClass
      when :false
        g.push_const :FalseClass
      when :nil
        g.push_const :NilClass
      when :self
        g.push_self
      else
        Atomy.const_from_string(g, @value.class.name)
      end
    end

    def matches?(g)
      g.push @value
      g.send :==, 1
    end
  end
end
