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
  # holds throwaway data used during compile time
  STATE = {}

  # operator precedence/associativity table
  OPERATORS = {}

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
end

class Array
  alias :head :first

  def tail
    drop(1)
  end

  alias :rest :tail
end
