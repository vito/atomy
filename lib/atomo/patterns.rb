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

  # include all pattern classes
  path = File.expand_path("../patterns", __FILE__)

  Dir["#{path}/*.rb"].sort.each do |f|
    require path + "/#{File.basename f}"
  end

  class Atomo::AST::Variable
    def to_pattern
      if @name == "_"
        Any.new
      else
        Named.new(@name, Any.new)
      end
    end
  end

  class Atomo::AST::Primitive
    def to_pattern
      Match.new(@value)
    end
  end

  class Atomo::AST::List
    def to_pattern
      List.new(@elements.collect(&:to_pattern))
    end
  end

  class Atomo::AST::Constant
    def to_pattern
      Constant.new(self)
    end
  end

  class Atomo::AST::ScopedConstant
    def to_pattern
      Constant.new(self)
    end
  end

  class Atomo::AST::ToplevelConstant
    def to_pattern
      Constant.new(self)
    end
  end

  class Atomo::AST::BinarySend
    def to_pattern
      case @operator
      when "."
        HeadTail.new(@lhs.to_pattern, @rhs.to_pattern)
      when "="
        Default.new(@lhs.to_pattern, @rhs)
      when "=="
        Strict.new(@rhs)
      when "?"
        Predicate.new(@private ? Any.new : @lhs.to_pattern, @rhs)
      end
    end
  end

  class Atomo::AST::Assign
    def to_pattern
      Default.new(@lhs.to_pattern, @rhs)
    end
  end

  class Atomo::AST::KeywordSend
    def to_pattern
      if @receiver.is_a?(Atomo::AST::Primitive) && @receiver.value == :self
        Named.new(@names[0], @arguments[0].to_pattern)
      end
    end
  end

  class Atomo::AST::BlockPass
    def to_pattern
      BlockPass.new(@body.to_pattern)
    end
  end

  class Atomo::AST::Quote
    def to_pattern
      Quote.new(@expression)
    end
  end

  class Atomo::AST::Block
    def to_pattern
      Metaclass.new(self)
    end
  end

  class Atomo::AST::GlobalVariable
    def to_pattern
      NamedGlobal.new(@identifier)
    end
  end

  class Atomo::AST::InstanceVariable
    def to_pattern
      NamedInstance.new(@identifier)
    end
  end

  class Atomo::AST::ClassVariable
    def to_pattern
      NamedClass.new(@identifier)
    end
  end

  class Atomo::AST::UnaryOperator
    def to_pattern
      case @operator
      when "$"
        NamedGlobal.new(@receiver.name)
      when "@@"
        NamedClass.new(@receiver.name)
      when "@"
        NamedInstance.new(@receiver.name)
      when "%"
        RuntimeClass.new(@receiver, nil)
      when "&"
        BlockPass.new(@receiver.to_pattern)
      when "*"
        Splat.new(@receiver.to_pattern)
      end
    end
  end

  class Atomo::AST::Splat
    def to_pattern
      Splat.new(@value.to_pattern)
    end
  end

  class Atomo::AST::Particle
    def to_pattern
      Particle.new(@name.to_sym) # TODO: other forms
    end
  end

  class Atomo::AST::UnarySend
    def to_pattern
      if @block
        Named.new(@method_name, @block.contents[0].to_pattern)
      else
        Unary.new(@receiver, @method_name)
      end
    end
  end

  class Atomo::AST::QuasiQuote
    def to_pattern
      QuasiQuote.new(@expression)
    end
  end
end
