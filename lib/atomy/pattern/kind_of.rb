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
  end
end
