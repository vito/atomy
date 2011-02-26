module Atomo::Patterns
  class Pattern
    attr_accessor :variable

    # push the target class for this pattern in a defition
    def target(g)
      raise Rubinius::CompileError, "no #target for #{self}"
    end

    # test if the pattern mtaches the value at the top of the stack
    # effect on the stack: top value removed, boolean pushed
    def matches?(g)
      raise Rubinius::CompileError, "no #matches? for #{self}"
    end

    # match the pattern on the value at the top of the stack
    # effect on the stack: top value removed
    def deconstruct(g, locals = {})
      g.pop
    end

    # try pattern-matching, erroring on failure
    # effect on the stack: top value removed
    def match(g)
      @variable = nil

      error = g.new_label
      done = g.new_label

      locals = {}
      local_names.each do |n|
        g.state.scope.assign_local_reference self
        locals[n] = @variable
      end

      g.dup
      matches?(g)
      g.gif error
      deconstruct(g, locals)
      g.goto done

      error.set!
      g.pop
      g.push_const :Exception
      g.push_literal "pattern mismatch"
      g.send :new, 1
      g.raise_exc

      done.set!
    end

    # create this pattern on the stack
    # effect on the stack: pattern object pushed
    def construct(g)
      raise Rubinius::CompileError, "no #construct for #{self}"
    end

    # local names bound by this pattern
    def local_names
      []
    end

    # number of locals
    def locals
      local_names.size
    end
  end

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
      return Constant.new(n.chain)
    when Atomo::AST::BinarySend
      case n.operator
      when "."
        return HeadTail.new(from_node(n.lhs), from_node(n.rhs))
      when "..."
        return Variadic.new(from_node(n.rhs))
      end
    when Atomo::AST::KeywordSend
      if n.receiver.is_a?(Atomo::AST::Primitive) && n.receiver.value == :self && n.arguments.size == 1
        return Named.new(n.method_name.chop, from_node(n.arguments[0]))
      end
    when Atomo::AST::BlockPass
      return BlockPass.new(from_node(n.body))
    end

    raise Exception.new("unknown pattern: " + n.inspect)
  end

  # include all pattern classes
  path = File.expand_path("../patterns", __FILE__)

  Dir["#{path}/*.rb"].sort.each do |f|
    require path + "/#{File.basename f}"
  end
end
