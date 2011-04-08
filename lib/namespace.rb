module Atomy
  NAMESPACES = {}

  class Namespace
    attr_reader :name, :using

    def initialize(name, using = [])
      @name = name
      @symbols = []
      @using = using
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

    def self.ensure(name)
      Thread.current[:atomy_namespace] =
        NAMESPACES[name] ||=
          new(name)
    end

    def self.get(name = nil)
      return NAMESPACES[name] if name
      Thread.current[:atomy_namespace]
    end

    def self.set(x)
      Thread.current[:atomy_namespace] = x
    end

    def self.register(sym, name = nil)
      ns = get(name && name.to_sym)
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

def Rubinius.bind_call(recv, nmeth, *args)
  ns_name, meth_name = nmeth.to_s.split("/")
  ns_name, meth_name = meth_name, ns_name unless meth_name

  if ns_name && ns_name == "_"
    ns = nil
  else 
    ns = Atomy::Namespace.get(!ns_name ? nil : ns_name.to_sym)
  end

  meth = meth_name.to_sym

  res = Rubinius::CallUnit.send_as(meth)

  if ns
    ([ns.name] + ns.using).reverse_each do |u|
      n = (u.to_s + "/" + meth.to_s).to_sym
      res = Rubinius::CallUnit.test(
        Rubinius::CallUnit.test_respond_to(n),
        Rubinius::CallUnit.send_as(n),
        res
      )
    end
  end

  res
end
