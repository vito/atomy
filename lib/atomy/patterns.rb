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

    # optimization for patterns such as With, so they can just
    # push_self rather than evaluating exprs on some new self
    def matches_self?(g)
      matches?(g)
    end

    # match the pattern on the value at the top of the stack
    # effect on the stack: top value removed
    def deconstruct(g, locals = {})
      g.pop
    end

    # helper for pushing the current class const onto the stack
    def get(g)
      Atomy.const_from_string(g, self.class.name)
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

    def wildcard?
      false
    end

    # try pattern-matching, erroring on failure
    # effect on the stack: top value removed
    def match(g, set = false, locals = {})
      local_names.each do |n|
        locals[n] ||= Atomy.assign_local(g, n, set)
      end

      mismatch = g.new_label
      done = g.new_label

      g.dup
      matches?(g)
      g.gif mismatch

      deconstruct(g, locals)

      g.goto done

      mismatch.set!
      g.push_self
      g.swap
      g.push_cpath_top
      g.find_const :Atomy
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
    def to_pattern
      raise "unknown pattern: #{inspect}"
    end
  end

  class Atomy::AST::Word
    def to_pattern
      if @text == "_"
        Any.new
      else
        Named.new(@text, Any.new)
      end
    end
  end

  class Atomy::AST::Primitive
    def to_pattern
      Match.new(@value)
    end
  end

  class Atomy::AST::Literal
    def to_pattern
      Atomy::Patterns::Literal.new(@value)
    end
  end

  class Atomy::AST::List
    def to_pattern
      List.new(@elements.collect(&:to_pattern))
    end
  end

  class Atomy::AST::Constant
    def to_pattern
      Constant.new(self)
    end
  end

  class Atomy::AST::ScopedConstant
    def to_pattern
      Constant.new(self)
    end
  end

  class Atomy::AST::ToplevelConstant
    def to_pattern
      Constant.new(self)
    end
  end

  class Atomy::AST::Binary
    def to_pattern
      case @operator
      when :"."
        HeadTail.new(@lhs.to_pattern, @rhs.to_pattern)
      when :"="
        Default.new(@lhs.to_pattern, @rhs)
      when :"?"
        Predicate.new(@private ? Any.new : @lhs.to_pattern, @rhs)
      else
        super
      end
    end
  end

  class Atomy::AST::Assign
    def to_pattern
      Default.new(@lhs.to_pattern, @rhs)
    end
  end

  class Atomy::AST::BlockPass
    def to_pattern
      BlockPass.new(@body.to_pattern)
    end
  end

  class Atomy::AST::Quote
    def to_pattern
      Quote.new(@expression)
    end
  end

  class Atomy::AST::Block
    def to_pattern
      SingletonClass.new(self)
    end
  end

  class Atomy::AST::GlobalVariable
    def to_pattern
      NamedGlobal.new(@identifier)
    end
  end

  class Atomy::AST::InstanceVariable
    def to_pattern
      NamedInstance.new(@identifier)
    end
  end

  class Atomy::AST::ClassVariable
    def to_pattern
      NamedClass.new(@identifier)
    end
  end

  class Atomy::AST::Unary
    def to_pattern
      case @operator
      when :"$"
        NamedGlobal.new(@receiver.text)
      when :"@"
        case @receiver
        when Atomy::AST::Unary
          if @receiver.operator == :"@"
            NamedClass.new(@receiver.receiver.text)
          else
            super
          end
        when Atomy::AST::Word
          NamedInstance.new(@receiver.text)
        else
          super
        end
      when :"&"
        BlockPass.new(@receiver.to_pattern)
      when :"*"
        Splat.new(@receiver.to_pattern)
      else
        super
      end
    end
  end

  class Atomy::AST::Splat
    def to_pattern
      Splat.new(@value.to_pattern)
    end
  end

  class Atomy::AST::String
    def to_pattern
      Atomy::Patterns::Literal.new(@value)
    end
  end

  class Atomy::AST::Compose
    def to_pattern
      if @right.is_a?(Atomy::AST::Block) and \
          @left.is_a?(Atomy::AST::Word)
        Named.new(@left.text, @right.contents[0].to_pattern)
      elsif @right.is_a?(Atomy::AST::Word)
        Attribute.new(@left, @right.text, [])
      elsif @right.is_a?(Atomy::AST::Call) and \
              @right.name.is_a?(Atomy::AST::Word)
        Attribute.new(@left, @right.name.text, @right.arguments)
      elsif @right.is_a?(Atomy::AST::List)
        Attribute.new(@left, :[], @right.elements)
      else
        super
      end
    end
  end

  class Atomy::AST::QuasiQuote
    def to_pattern
      QuasiQuote.new(self)
    end
  end
end
