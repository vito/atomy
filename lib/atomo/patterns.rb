class PatternMismatch < RuntimeError
  def initialize(p)
    @pattern = p
  end
end

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

    # helper for pushing the current class const onto the stack
    def get(g)
      self.class.name.split("::").each_with_index do |n, i|
        if i == 0
          g.push_const n.to_sym
        else
          g.find_const n.to_sym
        end
      end
    end

    # create the pattern on the stack
    def construct(g)
      raise Rubinius::CompileError, "no #construct for #{self}"
    end

    # try pattern-matching, erroring on failure
    # effect on the stack: top value removed
    def match(g, set = false)
      error = g.new_label
      done = g.new_label

      locals = {}
      local_names.each do |n|
        var = g.state.scope.search_local(@name)
        if var && (set || var.depth == 0)
          locals[n] = var
        else
          locals[n] = g.state.scope.new_local(n).reference
        end
      end

      g.dup
      matches?(g)
      g.gif error
      deconstruct(g, locals)
      g.goto done

      error.set!
      g.pop
      g.push_self
      g.push_const :PatternMismatch
      construct(g)
      g.send :new, 1
      g.allow_private
      g.send :raise, 1
      g.pop

      done.set!
    end

    # local names bound by this pattern
    def local_names
      []
    end

    # number of locals
    def locals
      local_names.size
    end

    # number of bindings
    def bindings
      0
    end

    # test if a pattern matches a value
    def ===(v)
      metaclass.dynamic_method(:===) do |g|
        g.total_args = g.required_args = g.local_count = 1
        g.push_local(0)
        matches?(g)
        g.ret
      end

      __send__ :===, v
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
    when Atomo::AST::Constant, Atomo::AST::ToplevelConstant,
         Atomo::AST::ScopedConstant
      return Constant.new(n)
    when Atomo::AST::BinarySend
      case n.operator
      when "."
        return HeadTail.new(from_node(n.lhs), from_node(n.rhs))
      when "="
        return Default.new(from_node(n.lhs), n.rhs)
      end
    when Atomo::AST::Assign
      return Default.new(from_node(n.lhs), n.rhs)
    when Atomo::AST::KeywordSend
      if n.receiver.is_a?(Atomo::AST::Primitive) && n.receiver.value == :self && n.arguments.size == 1
        return Named.new(n.method_name.chop, from_node(n.arguments[0]))
      end
    when Atomo::AST::BlockPass
      return BlockPass.new(from_node(n.body))
    when Atomo::AST::Quote
      return Quote.new(n.expression)
    when Atomo::AST::Block
      return Metaclass.new(n)
    when Atomo::AST::GlobalVariable
      return NamedGlobal.new(n.name)
    when Atomo::AST::InstanceVariable
      return NamedInstance.new(n.name)
    when Atomo::AST::ClassVariable
      return NamedClass.new(n.name)
    when Atomo::AST::UnaryOperator
      case n.operator
      when "$"
        return NamedGlobal.new(n.receiver.name)
      when "@@"
        return NamedClass.new(n.receiver.name)
      when "@"
        return NamedInstance.new(n.receiver.name)
      when "&"
        return BlockPass.new(from_node(n.receiver))
      when "*"
        return Splat.new(from_node(n.receiver))
      end
    when Atomo::AST::Splat
      return Splat.new(from_node(n.value))
    when Atomo::AST::Particle
      return Particle.new(n.name.to_sym) # TODO: other forms
    when Atomo::AST::UnarySend
      return Unary.new(n.receiver, n.method_name)
    when Atomo::AST::QuasiQuote
      return QuasiQuote.new(n.expression)
    end

    raise "unknown pattern: " + n.inspect
  end

  # include all pattern classes
  path = File.expand_path("../patterns", __FILE__)

  Dir["#{path}/*.rb"].sort.each do |f|
    require path + "/#{File.basename f}"
  end
end
