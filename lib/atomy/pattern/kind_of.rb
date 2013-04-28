require "atomy/pattern"
require "atomy/pattern/wildcard"

class Atomy::Pattern
  class KindOf < self
    attr_reader :code

    def initialize(code)
      @code = code
    end

    def matches?(gen)
      @code.bytecode(gen, nil)
      gen.swap
      gen.kind_of
    end

    def precludes?(other)
      !other.is_a?(Wildcard)
    end

    def target(gen)
      @code.bytecode(gen, nil)
    end

    def always_matches_self?
      true
    end

    def inlineable?
      false
    end
  end
end
