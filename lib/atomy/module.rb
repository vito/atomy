module Atomy
  class Module < ::Module
    attr_accessor :file, :delegate

    def initialize(file = :local)
      super()

      @file = file

      unless @file == :local
        Rubinius::Type.set_module_name(
          self,
          File.basename(file.to_s).to_sym,
          Object)
      end

      const_set(:Self, self)
    end

    def compile_context
      @compile_context ||=
        Binding.setup(
          Rubinius::VariableScope.current,
          Rubinius::CompiledMethod.current,
          Rubinius::StaticScope.new(self, Rubinius::StaticScope.new(Object)))
    end

    def compile(gen, node)
      expand(node).bytecode(gen, self)
    end

    def eval(string_or_node, debug = false)
      Atomy::Compiler.eval(
        string_or_node, self, compile_context, @file, 1, debug)
    end

    def inspect
      "\#<Atomy::Module '#{name}'>"
    end

    def make_send(node)
      node.to_send
    end

    def infix_info(op = nil)
      @infix ||= {}

      if op
        if @infix.key? op
          @infix[op]
        else
          using.each do |m|
            if info = m.infix_info(op)
              # cache
              @infix[op] = info
              return info
            end
          end

          # cache
          @infix[op] = nil
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

    def define_macro(pattern, body, file = @file)
      eval(Atomy::AST::DefineMacro.new(pattern.line, pattern, body))
    end

    def execute_macro(node)
      meth = node.macro_name
      send(meth, node) if respond_to? meth
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


    def execute_to_pattern(node, mod = self)
      _pattern(node, mod) if respond_to?(:_pattern)
    rescue Atomy::MethodFail => e
      # TODO: make sure this is never a false-positive
      raise unless e.method_name == :_pattern
    end

    def make_pattern_using(node, mod = self)
      if @delegate and res = @delegate.make_pattern(node)
        return res
      end

      using.each do |u|
        expanded = u.execute_to_pattern(node, mod)
        return expanded if expanded
      end

      nil
    end

    def make_pattern(node)
      with_context(:execute_to_pattern, node) ||
        with_context(:make_pattern_using, node) ||
        node.to_pattern
    rescue
      if node.respond_to?(:show)
        begin
          $stderr.puts "while patternizing #{node.show}"
        rescue
          $stderr.puts "while patternizing #{node.inspect}"
        end
      else
        $stderr.puts "while patternizing #{node.inspect}"
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
        as << Atomy::AST::Word.new(0, :"#{name}:sym:#{salt}")
      end

      if block
        block.call(*as)
      else
        as
      end
    end
  end
end
