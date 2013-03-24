require "atomy/node/pretty"

module Atomy
  class UnknownPattern < RuntimeError
    attr_reader :node

    def initialize(node)
      @node = node
    end

    def to_s
      "unknown pattern: #{node}"
    end
  end

  class UnknownCode < RuntimeError
    attr_reader :node

    def initialize(node)
      @node = node
    end

    def to_s
      "unknown code: #{node}"
    end
  end

  class PatternMismatch < RuntimeError
    attr_reader :pattern, :value

    def initialize(pattern, value)
      @pattern = pattern
      @value = value
    end

    def to_s
      "pattern `#{pattern}' did not match value `#{value.inspect}'"
    end
  end
end
