module Atomy::Patterns
  class Match < Pattern
    attributes(:value)

    def initialize(value)
      case value
      when :true, :false, :nil, :self, Fixnum, Bignum
        @value = value
      else
        raise ArgumentError, "unknown Match value: #{value.inspect}"
      end
    end

    def target(g, mod)
      case @value
      when :true
        g.push_cpath_top
        g.find_const :TrueClass
      when :false
        g.push_cpath_top
        g.find_const :FalseClass
      when :nil
        g.push_cpath_top
        g.find_const :NilClass
      when :self
        g.push_scope
        g.send :for_method_definition, 0
      when Fixnum
        g.push_cpath_top
        g.find_const :Fixnum
      when Bignum
        g.push_cpath_top
        g.find_const :Bignum
      end
    end

    def matches?(g, mod)
      g.push @value
      g.meta_send_op_equal g.find_literal(:==)
    end

    def always_matches_self?
      @value == :self
    end
  end
end
