module Atomy
  class Module < ::Module
    attr_accessor :file, :delegate

    def inspect
      "\#<Atomy::Module '#{name}'>"
    end

    def make_send(node)
      node.to_send
    end

    def infix_info(op = nil)
      @infix ||= {}

      if op
        if info = @infix[op]
          info
        else
          using.each do |m|
            if info = m.infix_info(op)
              return info
            end
          end

          nil
        end
      else
        @infix
      end
    end

    def infix(ops, prec = 60, assoc = :left)
      ops.split.each do |o|
        op =
          if o =~ /[\p{Ll}_]/u
            o.tr("-", "_").to_sym
          else
            o.to_sym
          end

        infix_info[op] = {
          :precedence => prec,
          :associativity => assoc.to_sym
        }
      end
    end

    def macro_definer(pattern, body)
      name = pattern.macro_name

      Atomy::AST::Define.new(
        0,
        Atomy::AST::Send.new(
          body.line,
          body,
          [],
          :to_node),
        Atomy::AST::Block.new(
          0,
          [Atomy::AST::Primitive.new(0, :self)],
          []),
        [ Atomy::AST::Compose.new(
            0,
            Atomy::AST::Word.new(0, :node),
            Atomy::AST::Block.new(
              0,
              [Atomy::AST::QuasiQuote.new(0, pattern)],
              []))
        ],
        name)
    end

    def define_macro(pattern, body, file = @file)
      macro_definer(pattern, body).evaluate(
        Binding.setup(
          TOPLEVEL_BINDING.variables,
          TOPLEVEL_BINDING.code,
          Rubinius::StaticScope.new(Atomy::AST, Rubinius::StaticScope.new(self)),
          self),
        file.to_s,
        pattern.line)
    end

    def execute_macro(node)
      meth = node.macro_name
      send(meth, node.copy) if respond_to? meth
    rescue Atomy::MethodFail => e
      # TODO: make sure this is never a false-positive
      raise unless e.method_name == meth
    end

    def expand_using(node)
      if @delegate and res = @delegate.expand_node(node)
        return res
      end

      using.each do |u|
        expanded = u.execute_macro(node)
        return expanded if expanded
      end

      nil
    end

    def expand_node(node)
      execute_macro(node) || expand_using(node)
    end

    def with_context(what, node)
      node.context && node.context != self &&
        node.context.send(what, node) ||
        send(what, node)
    end

    def expand(node)
      if direct = with_context(:execute_macro, node)
        expand(direct)
      elsif using = with_context(:expand_using, node)
        expand(using)
      else
        node
      end
    rescue
      if node.respond_to?(:show)
        begin
          $stderr.puts "while expanding #{node.show}"
        rescue
          $stderr.puts "while expanding #{node.inspect}"
        end
      else
        $stderr.puts "while expanding #{node.inspect}"
      end

      raise
    end

    def use(path)
      x = require(path)

      ([x] + x.exported_modules).reverse_each do |m|
        extend(m)
        include(m)
        using.unshift(m)
      end

      x
    end

    def using
      @using ||= []
    end

    def exported_modules
      @exported_modules ||= []
    end

    def export(*xs)
      xs.each do |x|
        case x
        when self.class
          exported_modules.unshift x
        else
          raise ArgumentError, "don't know how to export #{x.inspect}"
        end
      end

      self
    end

    # generate symbols
    def names(num = 0, &block)
      num = block.arity if block

      as = []
      num.times do
        salt = Atomy::Macro::Environment.salt!
        as << Atomy::AST::Word.new(0, :"s:#{salt}")
      end

      if block
        block.call(*as)
      else
        as
      end
    end
  end
end
