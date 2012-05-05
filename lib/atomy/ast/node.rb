module Atomy
  module AST
    module SentientNode
      # hash from attribute to the type of child node it is
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

      # TODO: spec for multi-splice
      def many_construct(n)
        x = <<END

          spliced = false
          size = 0
          @#{n}.each do |e|
            if e.splice? && d == 1
              g.make_array size
              g.send :+, 1 if spliced
              e.construct(g, mod, d)
              g.send :+, 1
              spliced = true
              size = 0
            else
              e.construct(g, mod, d)
              size += 1
            end
          end

          g.make_array size

          g.send :+, 1 if spliced
END
        x
      end

      # TODO: this is gross. do some rubinius macro magic?
      def generate
        all = []
        args = ""
        (@children[:required] + @children[:many] +
         @attributes[:required] + @attributes[:many]).each do |x|
          all << x.to_s
          args << ", #{x}_"
        end

        lists = @children[:many] + @attributes[:many]

        (@children[:optional] + @attributes[:optional]).each do |x, d|
          all << x.to_s
          args << ", #{x}_ = #{d}"
        end

        req_as =
          (@attributes[:required] + @attributes[:many]).collect { |a|
            ", @#{a}"
          }.join

        opt_as = @attributes[:optional].collect { |a, _|
            ", @#{a}"
          }.join

        creq_cs =
          @children[:required].collect { |n|
            ", f.call(@#{n})"
          }.join

        cmany_cs =
          @children[:many].collect { |n|
            ", @#{n}.collect { |n| f.call(n) }"
          }.join

        copt_cs =
          @children[:optional].collect { |n, _|
            ", @#{n} ? f.call(@#{n}) : nil"
          }.join

        child_names =
          @children[:required] + @children[:many] +
            @children[:optional].collect(&:first)

        attrs =
          @attributes[:required] + @attributes[:many] +
            @attributes[:optional].collect(&:first)

        all_ivars = child_names.collect { |n| "@#{n}" }

        copyreq_as =
          (@attributes[:required] + @attributes[:many]).collect { |a|
            ", @#{a}.copy"
          }.join

        copyopt_as = @attributes[:optional].collect { |a, _|
            ", @#{a}.copy"
          }.join

        copyreq_cs =
          @children[:required].collect { |n|
            ", @#{n}.copy"
          }.join

        copymany_cs =
          @children[:many].collect { |n|
            ", @#{n}.collect { |n| n.copy }"
          }.join

        copyopt_cs =
          @children[:optional].collect { |n, _|
            ", @#{n} ? @#{n}.copy : nil"
          }.join

        attr_accessor :line, *all

        class_eval <<EOF
          def initialize(line#{args})
            raise "initialized with non-integer `line': \#{line}" unless line.is_a?(Integer)
            #{@children[:required].collect { |n| "raise \"initialized with non-node `#{n}': \#{#{n}_.inspect}\" unless #{n}_ and #{n}_.is_a?(NodeLike)" }.join("; ")}
            #{@children[:many].collect { |n| "raise \"initialized with non-homogenous list `#{n}': \#{#{n}_.inspect}\" unless #{n}_.all? { |x| x.is_a?(NodeLike) }" }.join("; ")}
            #{@children[:optional].collect { |n, _| "raise \"initialized with non-node `#{n}': \#{#{n}_.inspect}\" unless #{n}_.nil? or #{n}_.is_a?(NodeLike)" }.join("; ")}

            @line = line
            #{all.collect { |a| "@#{a} = #{a}_" }.join("; ")}
          end

          def construct(g, mod, d = nil)
            get(g)
            g.push_int(@line)

            #{@children[:required].collect { |n|
                "@#{n}.construct(g, mod, d)"
              }.join("; ")}

            #{@children[:many].collect { |n|
                many_construct(n)
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

            g.send :new, #{all.size + 1}
            g.dup
            g.push_cpath_top
            g.find_const :Atomy
            g.send :current_module, 0
            g.send :in_context, 1
            g.pop
          end

          def eql?(b)
            b.kind_of?(self.class) \\
            #{all.collect { |a| " and @#{a}.eql?(b.#{a})" }.join}
          end

          alias :== :eql?

          def children(&f)
            if block_given?
              self.class.new(
                @line#{creq_cs + cmany_cs + req_as + copt_cs + opt_as})
            else
              [#{all_ivars.join(", ")}]
            end
          end

          def bottom?
            #{@children.values.flatten(1).empty?.inspect}
          end

          def details
            #{attrs.inspect}
          end

          def child_names
            #{child_names.inspect}
          end

          def copy
            self.class.new(
              @line#{copyreq_cs + copymany_cs + copyreq_as + copyopt_cs + copyopt_as}
            ).tap do |x|
              x.in_context(@context)
            end
          end
EOF
      end
    end

    module NodeLike
      attr_accessor :line

      # the module this node was constructed in
      attr_reader :context

      def accept(x)
        name = self.class.name
        meth = name && name.split("::").last.downcase.to_sym
        if x.respond_to?(meth)
          x.send(meth, self)
        else
          x.visit(self)
        end
      end

      def walk_with(b, stop = nil, &f)
        f.call(self, b)

        return if !b.is_a?(self.class) || (stop && stop.call(self, b))
        return if details != b.details

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

      def in_context(x)
        @context ||= x
      end

      def through_quotes(stop = nil, &f)
        ThroughQuotes.new(f, stop).go(self)
      end

      class ThroughQuotes
        def initialize(f, stop)
          @depth = 0
          @f = f
          @stop = stop
        end

        def go(x)
          x.accept self
        end

        def quasiquote(x)
          @depth += 1
          visit(x)
        ensure
          @depth -= 1
        end

        def unquote(x)
          @depth -= 1
          x.children do |c|
            go(c)
          end
        ensure
          @depth += 1
        end

        alias :splice :unquote

        def stop?(x)
          @stop && @stop.call(x)
        end

        def visit(x)
          new = x.children do |c|
            if @depth == 0 and stop?(x)
              c
            else
              go(c)
            end
          end

          if @depth == 0
            @f.call(new)
          else
            new
          end
        end
      end

      def unquote(d)
        return unless d
        d - 1
      end

      def quote(d)
        return unless d
        d + 1
      end

      def inspect
        draw(0)
      end

      def draw(depth)
        i = "  " * depth

        name = self.class.name.split("::").last

        attrs = details.collect do |d|
          "(#{d} = #{send(d)})"
        end

        childs = child_names.collect do |n|
          c = send(n)
          case c
          when Array
            drawn = c.collect { |n| n.draw(depth + 2) }
            "\n#{i}  #{n} = [\n#{drawn.join "\n"}\n#{i}  ]"
          when nil
            "\n#{i}  #{n} = nil"
          else
            "\n#{i}  #{n} =\n#{c.draw(depth + 2)}"
          end
        end

        "#{i}#{name} @ #{@line} #{attrs.join " "}#{childs.join}"
      end

      def get(g)
        Atomy.const_from_string(g, self.class.name)
      end

      def to_node
        self
      end

      def message_name
        nil
      end

      def unquote?
        false
      end

      def splice?
        false
      end

      def caller
        Send.new(
          @line,
          self,
          [],
          :call)
      end

      def evaluate(mod, bnd = nil, *args)
        if bnd.nil?
          bnd = Binding.setup(
            Rubinius::VariableScope.of_sender,
            Rubinius::CompiledMethod.of_sender,
            Rubinius::StaticScope.of_sender)
        end

        Atomy::Compiler.eval(self, mod, bnd, *args)
      end

      def macro_name
        :"_expand_#{self.class.name.split("::").last}"
      end

      def to_word
        nil
      end
    end

    class Node < Rubinius::AST::Node
      include NodeLike

      def self.inherited(sub)
        sub.extend SentientNode
      end

      def bytecode(g, mod)
        raise "no #bytecode for...\n#{inspect}"
      end
    end

    class Tree < Node
      children [:nodes]
      generate

      def bytecode(g, mod)
        @nodes.each.with_index do |n, i|
          mod.compile(g, n)
          g.pop unless i + 1 == @nodes.size
        end
      end

      def collect
        Tree.new(0, @nodes.collect { |n| yield n })
      end
    end

    class ScriptBody < Node
      generate

      def initialize(line, body)
        @line = line
        @body = body
      end

      def sprinkle_salt(g, diff)
        return if diff == 0

        g.push_cpath_top
        g.find_const :Atomy
        g.find_const :Macro
        g.find_const :Environment
        g.push diff
        g.send :salt!, 1
        g.pop
      end

      def bytecode(g, mod)
        pos(g)

        before = Atomy::Macro::Environment.salt

        @body.each.with_index do |n, i|
          g.pop unless i == 0

          mod.compile(g, n)
        end

        after = Atomy::Macro::Environment.salt

        sprinkle_salt(g, after - before)
      end
    end

    class EvalExpression < Rubinius::AST::EvalExpression
      def initialize(body)
        @pre_exe = []
        super
      end
      
      def bytecode(g, mod)
        container_bytecode(g) do
          @body.bytecode(g, mod)
          g.ret
        end
      end
    end

    class Script < Rubinius::AST::Container
      def initialize(body)
        @body = ScriptBody.new(body.line, body.nodes)
        @pre_exe = []
      end

      def bytecode(g, mod)
        @body.pos(g)

        super(g)

        container_bytecode(g) do
          g.push_state self

          g.push_self
          g.add_scope

          g.state.push_name @name

          @body.bytecode(g, mod)

          g.state.pop_name

          g.ret
          g.pop_state
        end
      end
    end
  end
end

class Object
  def to_node
    raise "cannot convert to a node: #{self.inspect}"
  end
end

class Integer
  def to_node
    Atomy::AST::Primitive.new -1, self
  end
end

class Float
  def to_node
    Atomy::AST::Literal.new -1, self
  end
end

class String
  def to_node
    Atomy::AST::StringLiteral.new -1, self
  end
end

class Array
  def to_node
    Atomy::AST::List.new(-1, collect(&:to_node))
  end
end

class NilClass
  def to_node
    Atomy::AST::Primitive.new -1, :nil
  end
end

class Symbol
  def to_node
    Atomy::AST::Literal.new -1, self
  end
end
