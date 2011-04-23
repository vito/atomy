module Atomy
  NAMESPACES = {}
  NAMESPACE_DELIM = "_ns_"

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

  class Namespace
    attr_reader :name, :using, :symbols

    def initialize(name, using = [])
      using = [:atomy] + using unless name == :atomy

      @name = name
      @using = using
      @symbols = []
    end

    def register(sym)
      @symbols << sym unless contains?(sym)
    end

    def contains?(sym)
      @symbols.include?(sym)
    end

    def use(sym)
      raise "namespace `#{sym}` tried to use itself" if sym == @name
      raise "unknown namespace `#{sym}'" unless ns = Namespace.get(sym)
      raise "circular namespaces: `#{@name}' <=> `#{sym}'" if ns.uses?(@name)
      @using << sym unless @using.include?(sym)
    end

    def uses?(ns)
      return true if @using.include?(ns)

      @using.each do |u|
        return true if Namespace.get(u).uses?(ns)
      end

      false
    end

    def resolve(sym)
      return @name if contains?(sym)

      @using.each do |ns|
        unless used = Namespace.get(ns)
          raise "unknown namespace: #{ns.inspect}"
        end

        return ns if used.contains?(sym)
      end

      nil
    end

    def top_down(&blk)
      yield @name
      @using.each do |u|
        Atomy::Namespace.get(u).top_down(&blk)
      end
      nil
    end

    def self.define_target
      Thread.current.atomy_get_local(:atomy_define_in) ||
        get && get.name.to_s
    end

    def self.ensure(name, using = [])
      Thread.current.atomy_set_local(
        :atomy_namespace,
        create(name, using)
      )
    end

    def self.create(name, using = [])
      NAMESPACES[name.to_sym] ||=
        new(name, using)
    end

    def self.get(name = nil)
      return NAMESPACES[name.to_sym] if name
      Thread.current.atomy_get_local(:atomy_namespace)
    end

    def self.set(x)
      Thread.current.atomy_set_local(:atomy_namespace, x)
    end

    def self.register(sym, name = nil)
      ns = get(name)
      return unless ns
      ns.register(sym)
    end

    def self.name
      ns = get
      return unless ns
      ns.name
    end

    def self.try_methods(name)
      ns_name, meth_name = Atomy.from_namespaced(name)

      if ns_name != "_" and \
          ns = Atomy::Namespace.get(ns_name && ns_name.to_sym)
        ns.top_down do |name|
          yield Atomy.namespaced(name, meth_name).to_sym
        end
      end

      meth_name.to_sym
    end
  end
end

class Thread
  def atomy_get_local(n)
    @locals[n]
  end

  def atomy_set_local(n, v)
    @locals[n] = v
  end
end

# NOTE: this is currently not used
# TODO: allow_private stuff
=begin
def Rubinius.bind_call(recv, nmeth, *args, &blk)
  ns_name, meth_name = Atomy.from_namespaced(nmeth)

  if ns_name == "_"
    ns = nil
  else 
    ns = Atomy::Namespace.get(!ns_name ? nil : ns_name.to_sym)
  end

  meth = meth_name.to_sym

  res = Rubinius::CallUnit.send_as(meth)

  if ns
    nss = [ns]
    scan = proc do |u|
      unless un = Atomy::Namespace.get(u) and \
              !nss.include?(un)
        next
      end

      nss << un
      un.using.each(&scan)
    end

    ns.using.each(&scan)

    nss.reverse_each do |n|
      next unless n.contains?(meth)
      m = Atomy.namespaced(n.name, meth).to_sym
      res = Rubinius::CallUnit.test(
        Rubinius::CallUnit.test_respond_to(m),
        Rubinius::CallUnit.send_as(m),
        res
      )
    end
  end

  res
end
=end

class Object
  alias :respond_to_atomy_old? :respond_to?

  def respond_to?(nmeth, include_private = false)
    return true if respond_to_atomy_old?(nmeth, include_private)

    Atomy::Namespace.try_methods(nmeth) do |m|
      return true if respond_to_atomy_old?(m, include_private)
    end

    false
  end

  def send(nmeth, *as, &blk)
    if respond_to_atomy_old?(nmeth, true)
      return __send__(nmeth, *as, &blk)
    end

    name = Atomy::Namespace.try_methods(nmeth) do |m|
      if respond_to_atomy_old?(m, true)
        return __send__(m, *as, &blk)
      end
    end

    __send__(name, *as, &blk)
  end

  alias_method :atomy_send, :send

  alias :method_atomy_old :method

  def method(nmeth)
    sym = Rubinius::Type.coerce_to_symbol nmeth
    cm = Rubinius.find_method(self, sym)

    return Method.new(self, cm[1], cm[0], sym) if cm

    name = Atomy::Namespace.try_methods(nmeth) do |m|
      cm = Rubinius.find_method(self, m)
      return Method.new(self, cm[1], cm[0], m) if cm
    end

    method_atomy_old(name)
  end
end

class Module
  # TODO: alias_method, instance_method, module_function, private,
  # private_class_method, protected, public, public_class_method
  #
  # TODO?: define_method, method_defined?, private_method_defined?,
  # protected_method_defined?, public_method_defined?, remove_method,
  # undef_method
end
