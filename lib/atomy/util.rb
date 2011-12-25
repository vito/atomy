# TODO: respond_to
module Kernel
  alias :method_missing_old :method_missing

  def method_missing_atomy(meth, *args, &blk)
    scope = Rubinius::StaticScope.of_sender
    while scope
      if scope.module.respond_to?(meth, true)
        return scope.module.send(meth, *args, &blk)
      else
        scope = scope.parent
      end
    end

    method_missing_old(meth, *args, &blk)
  end

  alias :method_missing :method_missing_atomy
end

class Rubinius::Generator
  def debug(name = "", quiet = false)
    if quiet
      push_literal(name + "\n")
    else
      dup
      send :inspect, 0
      push_literal name + ": "
      swap
      push_literal "\n"
      string_build 3
    end
    send :display, 0
    pop
  end
end

module Atomy
  # operator precedence/associativity table
  OPERATORS = {}

  def self.find_const(name, ctx)
    scope = ctx
    while scope
      if scope.module.const_defined?(name, false)
        return scope.module.const_get(name)
      end

      scope = scope.parent
    end

    scope = ctx
    while scope
      # TODO: use const_defined? once it searches parents
      begin
        return scope.module.const_get(name)
      rescue NameError
        scope = scope.parent
      end
    end

    ctx.module.const_missing(name)
  end

  def self.copy(x)
    case x
    when Symbol, Integer, true, false, nil
      x
    else
      x.dup
    end
  end

  def self.set_op_info(ops, assoc, prec)
    ops.each do |o|
      info = OPERATORS[o] ||= {}
      info[:assoc] = assoc
      info[:prec] = prec
    end
  end

  def self.unquote_splice(n)
    n.collect do |x|
      x = x.to_node
      Atomy::AST::Quote.new(x.line, x)
    end.to_node
  end

  def self.const_from_string(g, name)
    g.push_cpath_top
    name.split("::").each do |s|
      next if s.empty?
      g.find_const s.to_sym
    end
  end

  def self.assign_local(g, name, set = false)
    var = g.state.scope.search_local(name)

    if var && (set || var.depth == 0)
      var
    else
      g.state.scope.new_local(name).reference
    end
  end

  def self.current_module
    scope = Rubinius::StaticScope.of_sender
    mod = nil
    while scope
      if scope.module.is_a?(Atomy::Module)
        return scope.module
      end

      scope = scope.parent
    end

    nil
  end

  def self.make_wrapper_module(file = :local)
    mod = Atomy::Module.new do
      private_module_function

      # generate symbols
      def names(num = 0, &block)
        num = block.arity if block

        as = []
        num.times do
          salt = Atomy::Macro::Environment.salt!
          #raise("where") if salt == 689
          as << Atomy::AST::Word.new(0, :"s:#{salt}")
        end

        if block
          block.call(*as)
        else
          as
        end
      end
    end

    mod.const_set(:Self, mod)

    mod.file = file

    mod.singleton_class.dynamic_method(:__module_init__, file) do |g|
      g.push_self
      g.add_scope

      g.push_self
      g.send :private_module_function, 0
      g.pop

      g.push_variables
      g.push_scope
      g.make_array 2
      g.ret
    end

    vs, ss = mod.__module_init__
    bnd = Binding.setup(
      vs,
      vs.method,
      ss,
      mod
    )

    [mod, bnd]
  end
end

class Array
  alias :head :first

  def tail
    drop(1)
  end

  alias :rest :tail
end
