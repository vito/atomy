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

    def reset_slots
      @slots = {
        :required => [],
        :many => [],
        :optional => []
      }
    end

    def self.extended(sub)
      sub.reset_children
      sub.reset_attributes
      sub.reset_slots
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

    def slots(*specs)
      spec(@slots, specs)
    end

    def children(*specs)
      spec(@children, specs)
    end

    def generate
      all = []
      args = []
      (@children[:required] + @children[:many] +
        @attributes[:required] + @attributes[:many] +
        @slots[:required] + @slots[:many]).each do |x|
        all << x.to_s
        args << "#{x}_"
      end

      lists = @children[:many] + @attributes[:many] + @slots[:many]

      (@children[:optional] + @attributes[:optional]).each do |x, d|
        all << x.to_s
        args << "#{x}_ = #{d}"
      end

      non_slots = all.dup
      @slots[:optional].each do |x, d|
        all << x.to_s
        args << "#{x}_ = #{d}"
      end

      class_eval <<EOF
        attr_accessor #{all.collect { |a| ":#{a}" }.join(", ")}
EOF

      class_eval <<EOF
        def initialize(#{args.join ", "})
          #{@children[:required].collect { |n| "raise \"initialized with non-pattern `#{n}': \#{#{n}_.inspect}\" unless #{n}_ and #{n}_.is_a?(Pattern)" }.join("; ")}
          #{@children[:many].collect { |n| "raise \"initialized with non-homogenous list `#{n}': \#{#{n}_.inspect}\" unless #{n}_.all? { |x| x.is_a?(Pattern) }" }.join("; ")}
          #{@children[:optional].collect { |n, _| "raise \"initialized with non-pattern `#{n}': \#{#{n}_.inspect}\" unless #{n}_.nil? or #{n}_.is_a?(Pattern)" }.join("; ")}

          #{all.collect { |a| "@#{a} = #{a}_" }.join("; ")}
        end
EOF

      class_eval <<EOF
        def construct(g)
          get(g)

          #{@children[:required].collect { |n|
              "@#{n}.construct(g)"
            }.join("; ")}

          #{@children[:many].collect { |n|
              "@#{n}.each { |n| n.construct(g) }; g.make_array @#{n}.size"
            }.join("; ")}

          #{@attributes[:required].collect { |a|
              "g.push_literal(@#{a})"
            }.join("; ")}

          #{@attributes[:many].collect { |a|
              "@#{a}.each { |n| g.push_literal n }; g.make_array @#{a}.size"
            }.join("; ")}

          #{@slots[:required].collect { |a|
              "g.push_literal(@#{a})"
            }.join("; ")}

          #{@slots[:many].collect { |a|
              "@#{a}.each { |n| g.push_literal n }; g.make_array @#{a}.size"
            }.join("; ")}

          #{@children[:optional].collect { |n, _|
              "if @#{n}; @#{n}.construct(g, d); else; g.push_nil; end"
            }.join("; ")}

          #{@attributes[:optional].collect { |a, _|
              "g.push_literal(@#{a})"
            }.join("; ")}

          #{@slots[:optional].collect { |a, _|
              "g.push_literal(@#{a})"
            }.join("; ")}

          g.send :new, #{all.size}
        end
EOF

      class_eval <<EOF
        def eql?(b)
          b.kind_of?(#{self.name})#{non_slots.collect { |a| " and @#{a}.eql?(b.#{a})" }.join}
        end

        alias :== :eql?
EOF

      req_cs =
        @children[:required].collect { |n|
          "@#{n}.recursively(pre, post, :#{n}, &f)"
        }

      many_cs =
        @children[:many].collect { |n|
          "@#{n}.zip((0 .. @#{n}.size - 1).to_a).collect { |n, i| n.recursively(pre, post, [:#{n}, i], &f) }"
        }

      opt_cs =
        @children[:optional].collect { |n, _|
          "@#{n} ? @#{n}.recursively(pre, post, :#{n}, &f) : nil"
        }

      req_as =
        (@attributes[:required] + @attributes[:many]).collect { |a|
          "@#{a}"
        }

      opt_as = @attributes[:optional].collect { |a, _|
          "@#{a}"
        }

      req_ss =
        (@slots[:required] + @slots[:many]).collect { |a|
          "@#{a}"
        }

      opt_ss = @slots[:optional].collect { |a, _|
          "@#{a}"
        }

      class_eval <<EOF
        def recursively(pre = nil, post = nil, context = nil, &f)
          if pre and pre.arity == 2
            stop = pre.call(self, context)
          elsif pre
            stop = pre.call(self)
          else
            stop = false
          end

          if stop
            if f.arity == 2
              res = f.call(self, context)
              post.call(context) if post
              return res
            else
              res = f.call(self)
              post.call(context) if post
              return res
            end
          end

          recursed = #{self.name}.new(
            #{(req_cs + many_cs + req_as + req_ss + opt_cs + opt_as + opt_ss).join ", "}
          )

          if f.arity == 2
            res = f.call(recursed, context)
          else
            res = f.call(recursed)
          end

          post.call(context) if post

          res
        end
EOF

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

      all =
        (@children[:required] +
          @children[:many] +
          @children[:optional]).collect { |n, _| "@#{n}" }

      attrs =
        @attributes[:required] + @attributes[:many] +
          @attributes[:optional].collect(&:first)

      class_eval <<EOF
        def children(&f)
          if block_given?
            #{self.name}.new(
              #{(creq_cs + cmany_cs + req_as + req_ss + copt_cs + opt_as + opt_ss).join ", "}
            )
          else
            [#{all.join(", ")}]
          end
        end
EOF

      class_eval <<EOF
        def walk_with(b, stop = nil, &f)
          f.call(self, b)

          return if !b.is_a?(#{self.name}) || (stop && stop.call(self, b))

          #{attrs.collect { |a| "return if @#{a} != b.#{a}" }.join("; ")}

          children.zip(b.children).each do |x, y|
            if x.respond_to?(:each)
              num = [x.size, y.size].max
              num.times do |i|
                x2, y2 = x[i], y[i]
                if x2
                  x2.walk_with(y2, stop, &f)
                elsif y2
                  f.call(x2, y2)
                end
              end
            elsif x
              x.walk_with(y, stop, &f)
            elsif y
              # x is nil, y is not
              f.call(x, y)
            end
          end
        end
EOF

      class_eval <<EOF
        def bottom?
          #{@children.values.flatten(1).empty?.inspect}
        end
EOF

      class_eval <<EOF
        def details
          #{attrs.inspect}
        end
EOF

      slots =
        @slots[:required] + @slots[:many] +
          @slots[:optional].collect(&:first)

      class_eval <<EOF
        def slots
          #{slots.inspect}
        end
EOF

      required = @children[:required].collect { |c| ", [:\"#{c}\", @#{c}.to_sexp]" }.join
      many = @children[:many].collect { |c| ", [:\"#{c}\", @#{c}.collect(&:to_sexp)]" }.join
      optional = @children[:optional].collect { |c, _| ", [:\"#{c}\", @#{c} && @#{c}.to_sexp]" }.join

      a_required = @attributes[:required].collect { |c| ", [:\"#{c}\", @#{c}]" }.join
      a_many = @attributes[:many].collect { |c| ", [:\"#{c}\", @#{c}]" }.join
      a_optional = @attributes[:optional].collect { |c, _| ", [:\"#{c}\", @#{c}]" }.join

      s_required = @slots[:required].collect { |c| ", [:\"#{c}\", @#{c}]" }.join
      s_many = @slots[:many].collect { |c| ", [:\"#{c}\", @#{c}]" }.join
      s_optional = @slots[:optional].collect { |c, _| ", [:\"#{c}\", @#{c}]" }.join

      class_eval <<EOF
        def to_sexp
          [:"#{self.name.split("::").last.downcase}"#{required}#{many}#{optional}#{a_required}#{a_many}#{a_optional}#{s_required}#{s_many}#{s_optional}]
        end
EOF

    end
  end

  class Pattern
    def self.inherited(sub)
      sub.extend SentientPattern
    end

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
        Named.new(@right.contents[0].to_pattern, @left.text)
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
