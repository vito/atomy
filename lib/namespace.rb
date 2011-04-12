module Atomy
  NAMESPACES = {}

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
      @using << sym unless @using.include?(sym)
    end

    def resolve(sym)
      return @name if contains?(sym)

      @using.each do |ns|
        return ns if Namespace.get(ns).contains?(sym)
      end

      nil
    end

    def self.ensure(name, using = [])
      Thread.current[:atomy_namespace] =
        NAMESPACES[name.to_sym] ||=
          new(name, using)
    end

    def self.get(name = nil)
      return NAMESPACES[name.to_sym] if name
      Thread.current[:atomy_namespace]
    end

    def self.set(x)
      Thread.current[:atomy_namespace] = x
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
  end
end

def Rubinius.bind_call(recv, nmeth, *args, &blk)
  # TODO: foo/bar/baz should be foo/bar, baz
  # TODO: allow_private stuff
  ns_name, meth_name = nmeth.to_s.split("/")
  ns_name, meth_name = meth_name, ns_name unless meth_name

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
      m = (n.name.to_s + "/" + meth.to_s).to_sym
      res = Rubinius::CallUnit.test(
        Rubinius::CallUnit.test_respond_to(m),
        Rubinius::CallUnit.send_as(m),
        res
      )
    end
  end

  res
end
