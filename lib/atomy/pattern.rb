require "atomy/node/constructable"
require "rubinius/ast"

module Atomy
  class Pattern
    attr_accessor :from_node

    def ===(v)
      matches?(v)
    end

    def matches?(gen)
      raise NotImplementedError
    end

    def target
      raise NotImplementedError
    end

    def inline_matches?(gen)
      gen.push_literal(self)
      gen.swap
      gen.send(:matches?, 1)
    end
  end
end
