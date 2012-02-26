module Atomy::AST
  class Primitive < Node
    attributes :value
    generate

    def bytecode(g)
      pos(g)
      case @value
      when :true
        g.push_true
      when :false
        g.push_false
      when :self
        g.push_self
      when :nil
        g.push_nil
      when :undefined
        g.push_undef
      when Integer
        g.push_int @value
      else
        raise "unknown push argument #{@value.inspect}"
      end
    end
  end
end
