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
      # TODO: use const_defined? once it's fixed to search
      begin
        return scope.module.const_get(name)
      rescue NameError
        scope = scope.parent
      end
    end

    ctx.module.const_missing(name)
  end

  # note that this is only used for `foo' and `foo(...)' forms
  def self.send_message(recv, ctx, name, *args, &blk)
    Rubinius::CompiledMethod.current.scope =
      Rubinius::StaticScope.of_sender

    if recv.respond_to?(name, true)
      recv.__send__(name, *args, &blk)
    else
      scope = ctx
      while scope
        mod = scope.module

        if mod.respond_to?(name, true) &&
            !mod.class.method_defined?(name)
          return mod.__send__(name, *args, &blk)
        end

        scope = scope.parent
      end

      # TODO: this is to just trigger method_missing
      recv.__send__(name, *args, &blk)
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
    mod = Atomy::Module.new

    # just to make debugging a bit easier
    unless file == :local
      mod.set_name_if_necessary File.basename(file.to_s).to_sym, Object
    end

    mod.const_set(:Self, mod)

    mod.file = file

    mod.singleton_class.dynamic_method(:__module_init__, file) do |g|
      g.push_self
      g.add_scope

      g.push_self
      g.send :module_function, 0
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
      mod)

    [mod, bnd]
  end
end
