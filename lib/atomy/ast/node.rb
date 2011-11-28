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

      def many_construct(n)
        x = <<END

          spliced = false
          size = 0
          @#{n}.each do |e|
            if e.kind_of?(::Atomy::AST::Splice) && d == 1
              if size > 0
                g.make_array size
              end
              e.construct(g, d)
              g.send :+, 1 if size > 0 || spliced
              spliced = true
              size = 0
            else
              e.construct(g, d)
              size += 1
            end
          end

          g.make_array size

          g.send :+, 1 if spliced
END
        x
      end

      def generate
        all = []
        args = ""
        (@children[:required] + @children[:many] +
         @attributes[:required] + @attributes[:many] +
         @slots[:required] + @slots[:many]).each do |x|
          all << x.to_s
          args << ", #{x}_"
        end

        lists = @children[:many] + @attributes[:many] + @slots[:many]

        (@children[:optional] + @attributes[:optional]).each do |x, d|
          all << x.to_s
          args << ", #{x}_ = #{d}"
        end

        non_slots = all.dup
        @slots[:optional].each do |x, d|
          all << x.to_s
          args << ", #{x}_ = #{d}"
        end

        class_eval <<EOF
          attr_accessor :line#{all.collect { |a| ", :#{a}" }.join}
EOF

        class_eval <<EOF
          def initialize(line#{args})
            raise "initialized with non-integer `line': \#{line}" unless line.is_a?(Integer)
            #{@children[:required].collect { |n| "raise \"initialized with non-node `#{n}': \#{#{n}_.inspect}\" unless #{n}_ and #{n}_.is_a?(NodeLike)" }.join("; ")}
            #{@children[:many].collect { |n| "raise \"initialized with non-homogenous list `#{n}': \#{#{n}_.inspect}\" unless #{n}_.all? { |x| x.is_a?(NodeLike) }" }.join("; ")}
            #{@children[:optional].collect { |n, _| "raise \"initialized with non-node `#{n}': \#{#{n}_.inspect}\" unless #{n}_.nil? or #{n}_.is_a?(NodeLike)" }.join("; ")}

            @line = line
            #{all.collect { |a| "@#{a} = #{a}_" }.join("; ")}
          end
EOF

        class_eval <<EOF
          def construct(g, d = nil)
            get(g)
            g.push_int(@line)

            #{@children[:required].collect { |n|
                "@#{n}.construct(g, d)"
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

            g.send :new, #{all.size + 1}
          end
EOF

        class_eval <<EOF
          def eql?(b)
            b.kind_of?(#{name}) \\
            #{non_slots.collect { |a| " and @#{a}.eql?(b.#{a})" }.join}
          end

          alias :== :eql?
EOF

        req_as =
          (@attributes[:required] + @attributes[:many]).collect { |a|
            ", @#{a}"
          }.join

        opt_as = @attributes[:optional].collect { |a, _|
            ", @#{a}"
          }.join

        req_ss =
          (@slots[:required] + @slots[:many]).collect { |a|
            ", @#{a}"
          }.join

        opt_ss = @slots[:optional].collect { |a, _|
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
              #{name}.new(
                @line#{creq_cs + cmany_cs + req_as + req_ss + copt_cs + opt_as + opt_ss}
              )
            else
              [#{all.join(", ")}]
            end
          end
EOF

        class_eval <<EOF
          def walk_with(b, stop = nil, &f)
            f.call(self, b)

            return if !b.is_a?(#{name}) || (stop && stop.call(self, b))

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

        lower_name = name.split("::").last.downcase

        class_eval <<EOF
          def accept(x)
            if x.respond_to?(:#{lower_name})
              x.#{lower_name}(self)
            else
              x.visit(self)
            end
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
            [:"#{lower_name}"#{required}#{many}#{optional}#{a_required}#{a_many}#{a_optional}#{s_required}#{s_many}#{s_optional}]
          end
EOF

      end
    end

    module NodeLike
      attr_accessor :line

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
          :call
        )
      end

      def evaluate(bnd = nil, *args)
        if bnd.nil?
          bnd = Binding.setup(
            Rubinius::VariableScope.of_sender,
            Rubinius::CompiledMethod.of_sender,
            Rubinius::StaticScope.of_sender
          )
        end

        Atomy::Compiler.eval(self, bnd, *args)
      end

      # this is overridden by macro definitions
      def _expand
        self
      end

      def do_expand
        _expand.to_node
      end

      def msg_expand
        return do_expand unless macro_name and respond_to?(macro_name)
        send(macro_name)
      rescue MethodFail
        do_expand
      end

      def expand
        if lets = Atomy::Macro::Environment.let[self.class]
          x = self
          lets.reverse_each do |l|
            begin
              x = x.send(l)
              return x.expand unless x.kind_of?(self.class)
            rescue MethodFail
            end
          end
          x.msg_expand.to_node
        else
          msg_expand.to_node
        end
      rescue
        if respond_to?(:show)
          $stderr.puts "while expanding #{show}"
        else
          $stderr.puts "while expanding a #{to_sexp.inspect}"
        end

        raise
      end

      alias :prepare :expand

      def define_macro(body, file = :macro)
        pattern = macro_pattern

        unless macro_name
          @@stats ||= {}
          @@stats[self.class] ||= []
          @@stats[self.class] << self

          Atomy::Macro.register(
            self.class,
            pattern,
            body,
            Atomy::CodeLoader.compiling
          )

          return
        end

        Atomy::AST::Define.new(
          0,
          Atomy::AST::Compose.new(
            0,
            pattern.quoted,
            Atomy::AST::Word.new(0, macro_name)
          ),
          Atomy::AST::Send.new(
            body.line,
            Atomy::AST::Send.new(
              body.line,
              body,
              [],
              :to_node
            ),
            [],
            :expand
          )
        ).evaluate(
          Binding.setup(
            Rubinius::VariableScope.of_sender,
            Rubinius::CompiledMethod.of_sender,
            Rubinius::StaticScope.new(Atomy::AST)
          ), file.to_s, pattern.quoted.line
        )
      end

      def macro_name
        nil
      end

      def compile(g)
        prepare.bytecode(g)
      end

      def load_bytecode(g)
        compile(g)
      end

      def macro_pattern
        Atomy::Patterns::QuasiQuote.new(
          Atomy::AST::QuasiQuote.new(
            @line,
            self
          )
        )
      end
    end

    class Node < Rubinius::AST::Node
      include Atomy::Macro::Helpers
      include NodeLike

      def self.inherited(sub)
        sub.extend SentientNode
      end

      def bytecode(g)
        raise "no #bytecode for #{to_sexp}"
      end
    end

    class Tree < Node
      children [:nodes]
      generate

      def bytecode(g)
        @nodes.each { |n| n.compile(g) }
      end

      def collect
        Tree.new(0, @nodes.collect { |n| yield n })
      end
    end

    class Script < Rubinius::AST::Container
      def initialize(body)
        super body
        @name = :__script__
      end

      def sprinkle_salt(g, by)
        skip_salt = g.new_label

        g.push_cpath_top
        g.find_const :Atomy
        g.find_const :CodeLoader
        g.send :compiled?, 0
        g.git skip_salt

        g.push_cpath_top
        g.find_const :Atomy
        g.find_const :Macro
        g.find_const :Environment
        g.push by
        g.send :salt!, 1
        g.pop

        skip_salt.set!
      end

      def bytecode(g)
        super(g)

        container_bytecode(g) do
          g.push_state self

          when_load = g.new_label
          done_loading = g.new_label
          when_run = g.new_label
          start = g.new_label
          done = g.new_label

          g.push_cpath_top
          g.find_const :Atomy
          g.find_const :CodeLoader
          g.send :reason, 0
          g.push_literal :load
          g.send :==, 1
          g.git when_load

          done_loading.set!

          g.push_cpath_top
          g.find_const :Atomy
          g.find_const :CodeLoader
          g.send :reason, 0
          g.push_literal :run
          g.send :==, 1
          g.git when_run

          before = Atomy::Macro::Environment.salt

          start.set!
          @body.bytecode g

          after = Atomy::Macro::Environment.salt
          g.goto done

          when_load.set!

          sprinkle_salt(g, after - before) if after > before

          Atomy::CodeLoader.when_load.each do |e, c|
            if c
              skip = g.new_label

              g.push_cpath_top
              g.find_const :Atomy
              g.find_const :CodeLoader
              g.send :compiled?, 0
              g.git skip

              e.load_bytecode(g)
              g.pop

              skip.set!
            else
              e.load_bytecode(g)
              g.pop
            end
          end
          g.goto done_loading

          when_run.set!

          sprinkle_salt(g, after - before) if after > before

          Atomy::CodeLoader.when_run.each do |e, c|
            if c
              skip = g.new_label

              g.push_cpath_top
              g.find_const :Atomy
              g.find_const :CodeLoader
              g.send :compiled?, 0
              g.git skip

              e.load_bytecode(g)
              g.pop

              skip.set!
            else
              e.load_bytecode(g)
              g.pop
            end
          end
          g.goto start

          done.set!
          g.ret
          g.pop_state
        end
      end
    end
  end
end

class Object
  def to_node
    raise "not a node: #{self.inspect}"
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
    Atomy::AST::String.new -1, self
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
