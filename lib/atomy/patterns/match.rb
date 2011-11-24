module Atomy::Patterns
  class Match < Pattern
    attributes(:value)
    generate

    def target(g)
      case @value
      when :true
        g.push_const :TrueClass
      when :false
        g.push_const :FalseClass
      when :nil
        g.push_const :NilClass
      when :self
        g.push_scope
        g.send :for_method_definition, 0
      else
        Atomy.const_from_string(g, @value.class.name)
      end
    end

    def matches?(g)
      g.push @value
      g.meta_send_op_equal g.find_literal(:==)
    end
  end
end
