module Rubinius
  class StaticScope
    attr_accessor :atomy_visibility
  end
end

module Atomy
  class Module < ::Module
    attr_accessor :file, :delegate

    def make_send(node)
      node.to_send
    end

    def macro_definer(pattern, body)
      name = :_expand

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

    def define_macro(pattern, body, file)
      macro_definer(pattern, body).evaluate(
        Binding.setup(
          TOPLEVEL_BINDING.variables,
          TOPLEVEL_BINDING.code,
          Rubinius::StaticScope.new(Atomy::AST, Rubinius::StaticScope.new(self)),
          self),
        file.to_s,
        pattern.line)
    end

    # overridden by macro definitions
    def _expand(_)
      nil
    end

    def execute_macro(node)
      _expand(node.copy)
    rescue Atomy::MethodFail => e
      # TODO: make sure this is never a false-positive
      raise unless e.method_name == :_expand
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
          $stderr.puts "while expanding #{node.to_sexp.inspect}"
        end
      else
        $stderr.puts "while expanding #{node.to_sexp.inspect}"
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
      if block_given?
        scope = Rubinius::StaticScope.of_sender
        old = scope.atomy_visibility
        scope.atomy_visibility = :module

        begin
          yield
        ensure
          scope.atomy_visibility = old
        end
      elsif xs.empty?
        Rubinius::StaticScope.of_sender.atomy_visibility = :module
      else
        xs.each do |x|
          case x
          when Symbol
            singleton_class.set_visibility(meth, :public)
          when self.class
            exported_modules.unshift x
          else
            raise ArgumentError, "don't know how to export #{x.inspect}"
          end
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
end
