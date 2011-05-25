class Rubinius::Generator
  def debug(name = "")
    dup
    send :inspect, 0
    push_literal name + ": "
    swap
    push_literal "\n"
    string_build 3
    send :display, 0
    pop
  end
end

module Atomy
  def self.unquote_splice(n)
    n.collect do |x|
      x = x.to_node
      Atomy::AST::Quote.new(x.line, x)
    end.to_node
  end

  def self.const_from_string(g, name)
    g.push_cpath_top
    top = nil
    name.split("::").each do |s|
      next if s.empty?
      g.find_const s.to_sym
    end
  end

  def self.assign_local(g, name, set = false)
    if !set && g.state.scope.respond_to?(:pseudo_local)
      var = g.state.scope.pseudo_local(name)
    else
      var = g.state.scope.search_local(name)
    end

    if var && (set || var.depth == 0)
      var
    else
      g.state.scope.new_local(name).reference
    end
  end
end
