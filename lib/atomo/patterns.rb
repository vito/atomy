module Atomo::Pattern
  def self.from_node(n)
    case n
    when Atomo::AST::Variable
      if n.name == "_"
        return Any.new
      else
        return Named.new(n.name, Any.new)
      end
    when Atomo::AST::Primitive
      return Match.new(n.value)
    when Atomo::AST::List
      return List.new(n.elements.collect { |e| from_node(e) })
    when Atomo::AST::Tuple
      return Tuple.new(n.elements.collect { |e| from_node(e) })
    when Atomo::AST::Constant
      return Constant.new(n.name)
    when Atomo::AST::Operator
      case n.operator
      when "."
        return HeadTail.new(from_node(n.lhs), from_node(n.rhs))
      when "..."
        return Variadic.new(from_node(n.rhs))
      end
    when Atomo::AST::KeywordSend
      if n.receiver.is_a?(Atomo::AST::Primitive) && n.value == :self && n.arguments.size == 1
        return Named.new(n.method_name.chop, from_node(n.arguments[0]))
      end
    end

    raise Exception.new("unknown pattern: " + n.to_s)
  end

  # include all pattern classes
  # spec: match(x) should end up with the stack popped,
  # target(g) should push the pattern's target object
  path = File.expand_path("../patterns", __FILE__)

  Dir["#{path}/*.rb"].sort.each do |f|
    require path + "/#{File.basename f}"
  end
end