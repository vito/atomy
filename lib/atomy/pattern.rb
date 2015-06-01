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

    def locals
      []
    end

    def assign(scope, val)
      raise NotImplementedError unless locals.empty?
    end
  end
end
