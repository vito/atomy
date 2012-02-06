class Object
  alias copy dup
end

class Array
  def copy
    collect(&:copy)
  end
end

class Hash
  def copy
    new = {}
    each_pair do |k, v|
      new[k] = v.copy
    end
    new
  end
end

[Symbol, Integer, TrueClass, FalseClass, NilClass].each do |prim|
  prim.class_eval do
    def copy
      self
    end
  end
end
