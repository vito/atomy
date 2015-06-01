require "atomy/pattern"
require "atomy/pattern/wildcard"

class Atomy::Pattern
  class KindOf < self
    attr_reader :klass

    def initialize(klass)
      @klass = klass
    end

    def matches?(val)
      val.kind_of?(@klass)
    end

    def target
      @klass
    end
  end
end
