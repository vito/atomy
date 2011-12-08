module Rubinius
  class StaticScope
    attr_accessor :atomy_visibility
  end
end

class Module
  def export(*names)
    if block_given?
      scope = Rubinius::StaticScope.of_sender
      old = scope.atomy_visibility
      scope.atomy_visibility = :module

      begin
        yield
      ensure
        scope.atomy_visibility = old
      end
    elsif names.empty?
      Rubinius::StaticScope.of_sender.atomy_visibility = :module
    else
      names.each do |meth|
        singleton_class.set_visibility(meth, :public)
      end
    end

    self
  end

  def private_module_function(*args)
    if args.empty?
      Rubinius::StaticScope.of_sender.atomy_visibility = :private_module
    else
      sc = Rubinius::Type.object_singleton_class(self)
      args.each do |meth|
        method_name = Rubinius::Type.coerce_to_symbol meth
        mod, method = lookup_method(method_name)
        sc.method_table.store method_name, method.method, :private
        Rubinius::VM.reset_method_cache method_name
        set_visibility method_name, :private
      end

      return self
    end
  end
end

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

      # TODO: spec for multi-splice
      def many_construct(n)
        x = <<END

          spliced = false
          size = 0
          @#{n}.each do |e|
            if e.kind_of?(::Atomy::AST::Splice) && d == 1
              g.make_array size
              g.send :+, 1 if spliced
              e.construct(g, d)
              g.send :+, 1
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

        copyreq_as =
          (@attributes[:required] + @attributes[:many]).collect { |a|
            ", Atomy.copy(@#{a})"
          }.join

        copyopt_as = @attributes[:optional].collect { |a, _|
            ", Atomy.copy(@#{a})"
          }.join

        copyreq_ss =
          (@slots[:required] + @slots[:many]).collect { |a|
            ", Atomy.copy(@#{a})"
          }.join

        copyopt_ss = @slots[:optional].collect { |a, _|
            ", Atomy.copy(@#{a})"
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

        class_eval <<EOF
          def copy
            #{name}.new(
              @line#{copyreq_cs + copymany_cs + copyreq_as + copyreq_ss + copyopt_cs + copyopt_as + copyopt_ss}
            )
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
        c = copy
        return c.do_expand unless macro_name and respond_to?(macro_name)
        c.send(macro_name)
      rescue MethodFail
        c.do_expand
      end

      def expand
        if lets = Atomy::Macro::Environment.let[self.class]
          x = copy
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
          begin
            $stderr.puts "while expanding #{show}"
          rescue
            $stderr.puts "while expanding #{to_sexp.inspect}"
          end
        else
          $stderr.puts "while expanding #{to_sexp.inspect}"
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

    class ScriptBody < Node
      def initialize(line, body)
        @line = line
        @body = body
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
        @body.pos(g)

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
        @body.bytecode(g)

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
      end
    end

    class Script < Rubinius::AST::Container
      def initialize(body)
        @body = ScriptBody.new(body.line, body)
        @name = :__script__
      end

      def attach_and_call(g, arg_name, scoped=false, pass_block=false)
        name = @name || arg_name
        meth = new_generator(g, name)

        meth.push_state self

        if scoped
          meth.push_self
          meth.add_scope
        end

        meth.state.push_name name

        meth.push_self
        meth.send :private_module_function, 0
        meth.pop

        @body.bytecode meth

        meth.state.pop_name

        meth.ret
        meth.close

        meth.local_count = local_count
        meth.local_names = local_names

        meth.pop_state

        g.dup
        g.push_rubinius
        g.swap
        g.push_literal arg_name
        g.swap
        g.push_generator meth
        g.swap
        g.push_scope
        g.swap
        g.send :attach_method, 4
        g.pop

        if pass_block
          g.push_block
          g.send_with_block arg_name, 0
        else
          g.send arg_name, 0
        end

        return meth
      end

      def bytecode(g)
        @body.pos(g)

        super(g)

        container_bytecode(g) do
          g.push_state self

          g.push_cpath_top
          g.find_const :Module
          g.send :new, 0
          g.dup
          g.swap
          g.push_literal :Self
          g.swap
          g.send :const_set, 2

          g.dup
          attach_and_call(g, :__module_init__, true)
          g.pop

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
