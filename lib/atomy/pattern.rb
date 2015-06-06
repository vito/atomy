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

    def assign(_, _)
    end

    def target
      raise NotImplementedError
    end
  end
end
