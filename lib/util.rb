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
  NAMESPACE_DELIM = "/"

  def self.const_from_string(g, name)
    g.push_cpath_top
    top = nil
    name.split("::").each do |s|
      next if s.empty?
      g.find_const s.to_sym
    end
  end

  def self.namespaced(ns, name)
    return name.to_s if !ns or ns == "_"
    ns.to_s + NAMESPACE_DELIM + name.to_s
  end

  def self.from_namespaced(resolved)
    split = resolved.to_s.split(NAMESPACE_DELIM)
    meth_name = split.pop
    ns_name = !split.empty? && split.join(NAMESPACE_DELIM)
    [ns_name, meth_name]
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
