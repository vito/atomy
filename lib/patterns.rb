class PatternMismatch < RuntimeError
  def initialize(p, v)
    @pattern = p
    @value = v
  end
end

module Atomy::Patterns
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
      g.push_cpath_top
      self.class.name.split("::").each do |n|
        g.find_const n.to_sym
      end
    end

    # create the pattern on the stack
    def construct(g)
      raise Rubinius::CompileError, "no #construct for #{self}"
    end

    def assign(g, expr, set = false)
      locals = {}
      local_names.each do |n|
        locals[n] = Atomy.assign_local(g, n, set)
      end

      expr.compile(g)
      g.dup
      match(g, set, locals)
    end

    # try pattern-matching, erroring on failure
    # effect on the stack: top value removed
    def match(g, set = false, locals = {})
      mismatch = g.new_label
      done = g.new_label

      local_names.each do |n|
        locals[n] ||= Atomy.assign_local(g, n, set)
      end

      g.dup
      matches?(g)
      g.gif mismatch

      deconstruct(g, locals)
      g.goto done

      mismatch.set!
      g.push_self
      g.swap
      g.push_cpath_top
      g.find_const :PatternMismatch
      g.swap
      construct(g)
      g.swap
      g.send :new, 2
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
      locals
    end

    # test if a pattern matches a value
    def ===(v)
      singleton_class.dynamic_method(:===) do |g|
        g.total_args = g.required_args = g.local_count = 1
        g.push_local(0)
        matches?(g)
        g.ret
      end

      __send__ :===, v
    end

    def to_node
      Atomy::AST::Pattern.new(0, self)
    end
  end

  # include all pattern classes
  path = File.expand_path("../patterns", __FILE__)

  Dir["#{path}/*.rb"].sort.each do |f|
    require path + "/#{File.basename f}"
  end

  class Atomy::AST::Node
    def pattern
      raise "unknown pattern: #{inspect}"
    end
  end

  class Atomy::AST::Variable
    def pattern
      if @name == "_"
        Any.new
      else
        Named.new(@name, Any.new)
      end
    end
  end

  class Atomy::AST::Primitive
    def pattern
      Match.new(@value)
    end
  end

  class Atomy::AST::List
    def pattern
      List.new(@elements.collect(&:to_pattern))
    end
  end

  class Atomy::AST::Constant
    def pattern
      Constant.new(self)
    end
  end

  class Atomy::AST::ScopedConstant
    def pattern
      Constant.new(self)
    end
  end

  class Atomy::AST::ToplevelConstant
    def pattern
      Constant.new(self)
    end
  end

  class Atomy::AST::BinarySend
    def pattern
      case @operator
      when "."
        HeadTail.new(@lhs.to_pattern, @rhs.to_pattern)
      when "="
        Default.new(@lhs.to_pattern, @rhs)
      when "?"
        Predicate.new(@private ? Any.new : @lhs.to_pattern, @rhs)
      end
    end
  end

  class Atomy::AST::Assign
    def pattern
      Default.new(@lhs.to_pattern, @rhs)
    end
  end

  class Atomy::AST::BlockPass
    def pattern
      BlockPass.new(@body.to_pattern)
    end
  end

  class Atomy::AST::Quote
    def pattern
      Quote.new(@expression)
    end
  end

  class Atomy::AST::Block
    def pattern
      SingletonClass.new(self)
    end
  end

  class Atomy::AST::GlobalVariable
    def pattern
      NamedGlobal.new(@identifier)
    end
  end

  class Atomy::AST::InstanceVariable
    def pattern
      NamedInstance.new(@identifier)
    end
  end

  class Atomy::AST::ClassVariable
    def pattern
      NamedClass.new(@identifier)
    end
  end

  class Atomy::AST::Unary
    def pattern
      case @operator
      when "$"
        NamedGlobal.new(@receiver.name)
      when "@"
        case @receiver
        when Atomy::AST::Unary
          NamedClass.new(@receiver.receiver.name)
        else
          NamedInstance.new(@receiver.name)
        end
      when "%"
        RuntimeClass.new(@receiver, nil)
      when "&"
        BlockPass.new(@receiver.to_pattern)
      when "*"
        Splat.new(@receiver.to_pattern)
      end
    end
  end

  class Atomy::AST::Splat
    def pattern
      Splat.new(@value.to_pattern)
    end
  end

  class Atomy::AST::String
    def pattern
      Match.new(@value)
    end
  end

  class Atomy::AST::Particle
    def pattern
      Particle.new(@name.to_sym) # TODO: other forms
    end
  end

  class Atomy::AST::Send
    def pattern
      if @block
        Named.new(@method_name, @block.contents[0].to_pattern)
      else
        Attribute.new(@receiver, @method_name, @arguments)
      end
    end
  end

  class Atomy::AST::QuasiQuote
    def pattern
      QuasiQuote.new(self)
    end
  end
end
