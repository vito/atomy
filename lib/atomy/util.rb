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
    undefined = Rubinius.asm { set_line 0; push_undef }

    # search in immediate context
    scope = ctx
    while scope
      find = scope.module.constant_table.fetch name, undefined

      return find unless find.equal?(undefined)

      scope = scope.parent
    end

    scope = ctx
    while scope
      current = scope.module

      while current
        find = current.constant_table.fetch name, undefined

        return find unless find.equal?(undefined)

        current = current.direct_superclass
      end

      scope = scope.parent
    end

    find = Object.constant_table.fetch name, undefined

    return find unless find.equal?(undefined)

    ctx.module.const_missing(name)
  end

  def self.unquote_splice(n)
    Atomy::AST::Prefix.new(
      0,
      n.collect do |x|
        x = x.to_node
        Atomy::AST::Quote.new(x.line, x)
      end.to_node,
      :*)
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
    scope = Rubinius::ConstantScope.of_sender
    while scope
      if scope.module.is_a?(Atomy::Module)
        return scope.module
      end

      scope = scope.parent
    end

    nil
  end
end
