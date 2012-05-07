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
            name = s[0]
            if s.size == 2
              into[:optional] << s
            else
              into[:many] << name
            end
          elsif s.to_s[-1] == ??
            name = s.to_s[0..-2].to_sym
            into[:optional] << [name, nil]
          else
            name = s
            into[:required] << name
          end

          attr_accessor name
        end

        into
      end

      def attributes(*specs)
        spec(@attributes, specs)
      end

      def children(*specs)
        spec(@children, specs)
      end
    end

    module NodeLike
      attr_accessor :line

      # the module this node was constructed in
      attr_reader :context

      def initialize(line, *args)
        @line = line

        childs = self.class.children
        attrs = self.class.attributes

        arg = 0
        childs[:required].each do |n|
          send(:"#{n}=", args[arg])
          arg += 1
        end

        childs[:many].each do |n|
          send(:"#{n}=", args[arg])
          arg += 1
        end

        attrs[:required].each do |n|
          send(:"#{n}=", args[arg].freeze)
          arg += 1
        end

        attrs[:many].each do |n|
          send(:"#{n}=", args[arg].freeze)
          arg += 1
        end

        childs[:optional].each do |n, d|
          send(:"#{n}=", args.size > arg ? args[arg] : d)
          arg += 1
        end

        attrs[:optional].each do |n, d|
          send(:"#{n}=", args.size > arg ? args[arg].freeze : d)
          arg += 1
        end
      end

      def children(&f)
        childs = self.class.children

        if block_given?
          attrs = self.class.attributes

          args = []

          childs[:required].each do |n|
            args << f.call(send(n))
          end

          childs[:many].each do |n|
            args << send(n).collect { |x| f.call(x) }
          end

          attrs[:required].each do |n|
            args << send(n)
          end

          attrs[:many].each do |n|
            args << send(n)
          end

          childs[:optional].each do |n, _|
            args <<
              if val = send(n)
                f.call(val)
              end
          end

          attrs[:optional].each do |n, _|
            args << send(n)
          end

          self.class.new(@line, *args)
        else
          child_names.collect { |n| send(n) }
        end
      end
      
      def eql?(b)
        b.kind_of?(self.class) &&
          children.eql?(b.children) &&
          details.eql?(b.details)
      end

      alias :== :eql?

      def copy
        childs = self.class.children
        attrs = self.class.attributes

        x = dup

        childs[:required].each do |n|
          x.send(:"#{n}=", x.send(n).copy)
        end

        childs[:many].each do |n|
          x.send(:"#{n}=", x.send(n).copy)
        end

        attrs[:required].each do |n|
          x.send(:"#{n}=", x.send(n).copy)
        end

        attrs[:many].each do |n|
          x.send(:"#{n}=", x.send(n).copy)
        end

        childs[:optional].each do |n, _|
          val = x.send(n)
          x.send(:"#{n}=", val && val.copy)
        end

        x
      end

      def construct(g, mod, d = nil)
        get(g)
        g.push_int(@line)

        childs = self.class.children
        attrs = self.class.attributes

        args = 1
        childs[:required].each do |n|
          send(n).construct(g, mod, d)
          args += 1
        end

        childs[:many].each do |n|
          spliced = false
          size = 0
          send(n).each do |e|
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

          args += 1
        end

        attrs[:required].each do |n|
          g.push_literal(send(n))
          args += 1
        end

        attrs[:many].each do |n|
          vals = send(n)

          vals.each do |v|
            g.push_literal(v)
          end

          g.make_array vals.size

          args += 1
        end

        childs[:optional].each do |n, _|
          if v = send(n)
            v.construct(g, mod, d)
          else
            g.push_nil
          end

          args += 1
        end

        attrs[:optional].each do |n, _|
          g.push_literal(send(n))
          args += 1
        end

        g.send :new, args
        g.dup
        g.push_cpath_top
        g.find_const :Atomy
        g.send :current_module, 0
        g.send :in_context, 1
        g.pop
      end

      def child_names
        childs = self.class.children
        childs[:required] + childs[:many] +
          childs[:optional].collect(&:first)
      end

      def attribute_names
        attrs = self.class.attributes
        attrs[:required] + attrs[:many] +
          attrs[:optional].collect(&:first)
      end

      def details
        attribute_names.collect { |n| send(n) }
      end

      def bottom?
        self.class.children.all? do |k, v|
          v.empty?
        end
      end

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

        attrs = attribute_names.collect do |d|
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
