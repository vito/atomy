module Atomy::Patterns
  module SentientPattern
    # hash from attribute to the type of child pattern it is
    # :normal = normal, required subnode
    # :many = a list of subnodes
    # :optional = optional (might be nil)
    def reset_children
      @children = {
        :required => [],
        :many => [],
        :optional => []
      }
    end

    def reset_attributes
      @attributes = {
        :required => [],
        :many => [],
        :optional => []
      }
    end

    def self.extended(sub)
      sub.reset_children
      sub.reset_attributes
    end

    def spec(into, specs)
      specs.each do |s|
        if s.respond_to?(:[]) and s.respond_to?(:size)
          if s.size == 2
            into[:optional] << s
          else
            into[:many] << s[0]
          end
        elsif s.to_s[-1] == ??
          into[:optional] << [s.to_s[0..-2].to_sym, "nil"]
        else
          into[:required] << s
        end
      end

      into
    end

    def attributes(*specs)
      spec(@attributes, specs)
    end

    def children(*specs)
      spec(@children, specs)
    end

    def generate
      all = []
      args = []
      (@children[:required] + @children[:many] +
        @attributes[:required] + @attributes[:many]).each do |x|
        all << x.to_s
        args << "#{x}_"
      end

      lists = @children[:many] + @attributes[:many]

      (@children[:optional] + @attributes[:optional]).each do |x, d|
        all << x.to_s
        args << "#{x}_ = #{d}"
      end

      req_as =
        (@attributes[:required] + @attributes[:many]).collect { |a|
          "@#{a}"
        }

      opt_as = @attributes[:optional].collect { |a, _|
          "@#{a}"
        }

      creq_cs =
        @children[:required].collect { |n|
          "f.call(@#{n})"
        }

      cmany_cs =
        @children[:many].collect { |n|
          "@#{n}.collect { |n| f.call(n) }"
        }

      copt_cs =
        @children[:optional].collect { |n, _|
          "@#{n} ? f.call(@#{n}) : nil"
        }

      all_ivars =
        (@children[:required] +
          @children[:many] +
          @children[:optional]).collect { |n, _| "@#{n}" }

      attrs =
        @attributes[:required] + @attributes[:many] +
          @attributes[:optional].collect(&:first)

      attr_accessor :line, *all

      class_eval <<EOF
        def initialize(#{args.join ", "})
          #{@children[:required].collect { |n| "raise \"initialized with non-pattern `#{n}': \#{#{n}_.inspect}\" unless #{n}_ and #{n}_.is_a?(Pattern)" }.join("; ")}
          #{@children[:many].collect { |n| "raise \"initialized with non-homogenous list `#{n}': \#{#{n}_.inspect}\" unless #{n}_.all? { |x| x.is_a?(Pattern) }" }.join("; ")}
          #{@children[:optional].collect { |n, _| "raise \"initialized with non-pattern `#{n}': \#{#{n}_.inspect}\" unless #{n}_.nil? or #{n}_.is_a?(Pattern)" }.join("; ")}

          #{all.collect { |a| "@#{a} = #{a}_" }.join("; ")}
        end

        def construct(g, mod)
          get(g)

          #{@children[:required].collect { |n|
              "@#{n}.construct(g, mod)"
            }.join("; ")}

          #{@children[:many].collect { |n|
              "@#{n}.each { |n| n.construct(g, mod) }; g.make_array @#{n}.size"
            }.join("; ")}

          #{@attributes[:required].collect { |a|
              "g.push_literal(@#{a})"
            }.join("; ")}

          #{@attributes[:many].collect { |a|
              "@#{a}.each { |n| g.push_literal n }; g.make_array @#{a}.size"
            }.join("; ")}

          #{@children[:optional].collect { |n, _|
              "if @#{n}; @#{n}.construct(g, mod, d); else; g.push_nil; end"
            }.join("; ")}

          #{@attributes[:optional].collect { |a, _|
              "g.push_literal(@#{a})"
            }.join("; ")}

          g.send :new, #{all.size}
          g.dup
          g.push_cpath_top
          g.find_const :Atomy
          g.send :current_module, 0
          g.send :in_context, 1
          g.pop
        end

        def eql?(b)
          b.kind_of?(self.class)#{all.collect { |a| " and @#{a}.eql?(b.#{a})" }.join}
        end

        alias :== :eql?

        def children(&f)
          if block_given?
            self.class.new(
              #{(creq_cs + cmany_cs + req_as + copt_cs + opt_as).join ", "})
          else
            [#{all_ivars.join(", ")}]
          end
        end
EOF
    end
  end

  class Pattern
    def self.inherited(sub)
      sub.extend SentientPattern
    end

    # the module this node was constructed in
    attr_reader :context

    def in_context(x)
      @context ||= x
    end

    # helper for pushing the current class const onto the stack
    def get(g)
      Atomy.const_from_string(g, self.class.name)
    end

    # create the pattern on the stack
    def construct(g, mod)
      raise Rubinius::CompileError, "no #construct for #{self}"
    end

    # push the target class for this pattern in a defition
    def target(g, mod)
      raise Rubinius::CompileError, "no #target for #{self}"
    end

    # test if the pattern mtaches the value at the top of the stack
    # effect on the stack: top value removed, boolean pushed
    def matches?(g, mod)
      raise Rubinius::CompileError, "no #matches? for #{self}"
    end

    # optimization for patterns such as With, so they can just
    # push_self rather than evaluating exprs on some new self
    def matches_self?(g, mod)
      matches?(g, mod)
    end

    # match the pattern on the value at the top of the stack
    # effect on the stack: top value removed
    def deconstruct(g, mod, locals = {})
      g.pop
    end

    # pattern-matching assignment on an expr
    # effect on the stack: expr's value pushed
    def assign(g, mod, expr, set = false)
      locals = {}
      local_names.each do |n|
        locals[n] = Atomy.assign_local(g, n, set)
      end

      mod.compile(g, expr)
      g.dup
      match(g, mod, set, locals)
    end

    # try pattern-matching, erroring on failure
    # effect on the stack: top value removed
    def match(g, mod, set = false, locals = {})
      local_names.each do |n|
        locals[n] ||= Atomy.assign_local(g, n, set)
      end

      unless wildcard?
        mismatch = g.new_label
        done = g.new_label

        g.dup
        matches?(g, mod)
        g.gif mismatch
      end

      deconstruct(g, mod, locals)

      unless wildcard?
        g.goto done

        mismatch.set!
        g.push_self
        g.swap
        g.push_cpath_top
        g.find_const :Atomy
        g.find_const :PatternMismatch
        g.swap
        get(g)
        g.swap
        g.send :new, 2
        g.allow_private
        g.send :raise, 1
        g.pop

        done.set!
      end
    end

    # will this pattern match everything?
    def wildcard?
      false
    end

    # does this pattern always match `self' if it's the receiver pattern?
    def always_matches_self?
      wildcard?
    end

    # local names bound by this pattern, not including children
    def names
      []
    end

    # a Set of all locals provided by this pattern
    def local_names
      ns = Set.new names
      children do |p|
        ns += p.local_names
        p
      end
      ns
    end

    # number of locals
    def locals
      local_names.size
    end

    # does the pattern perform any binding/assignment?
    def binds?
      children do |p|
        return true if p.binds?
        p
      end

      false
    end

    # test if a pattern matches a value
    def ===(v)
      singleton_class.dynamic_method(:===) do |g|
        g.total_args = g.required_args = g.local_count = 1
        g.push_local(0)
        matches?(g, @context)
        g.ret
      end

      __send__ :===, v
    end

    # get the pattern's definition target
    def definition_target
      singleton_class.dynamic_method(:definition_target) do |g|
        g.total_args = g.required_args = g.local_count = 0
        target(g, @context)
        g.ret
      end

      __send__ :definition_target
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
      raise "unknown pattern:\n#{inspect}"
    end
  end

  class Atomy::AST::Word
    def to_pattern
      if @text == :_
        Any.new
      else
        Named.new(Any.new, @text)
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

  class Atomy::AST::Infix
    def to_pattern
      case @operator
      when :"."
        HeadTail.new(@left.to_pattern, @right.to_pattern)
      when :"="
        Default.new(@left.to_pattern, @right)
      when :"?"
        Predicate.new(@private ? Any.new : @left.to_pattern, @right)
      else
        super
      end
    end
  end

  class Atomy::AST::Assign
    def to_pattern
      Default.new(@left.to_pattern, @right)
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
      SingletonClass.new(body)
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

  class Atomy::AST::Prefix
    def to_pattern
      case @operator
      when :"$"
        NamedGlobal.new(@receiver.text)
      when :"@"
        case @receiver
        when Atomy::AST::Prefix
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
        Named.new(@right.contents[0].to_pattern, @left.text)
      elsif @right.is_a?(Atomy::AST::Word)
        Attribute.new(@left, @right.text, [])
      elsif @right.is_a?(Atomy::AST::Call) and \
              @right.name.is_a?(Atomy::AST::Word)
        Attribute.new(@left, @right.name.text, @right.arguments)
      elsif @right.is_a?(Atomy::AST::List)
        Attribute.new(@left, :[], @right.elements)
      elsif @right.is_a?(Atomy::AST::Constant)
        if @left.is_a?(Atomy::AST::Word) and \
             @left.text == :_
          Constant.new(Atomy::AST::ToplevelConstant.new(@line, @right.name))
        else
          Constant.new(Atomy::AST::ScopedConstant.new(@line, @left, @right.name))
        end
      else
        super
      end
    end
  end

  class Atomy::AST::QuasiQuote
    def to_pattern
      QuasiQuote.new(
        through_quotes(proc { true }) do |e|
          e.to_pattern.to_node
        end)
    end
  end
end
