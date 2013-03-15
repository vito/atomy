module Atomy
  class Code
    def bytecode(gen, mod)
      raise NotImplementedError,
        "code #{self.class} does not implement #bytecode"
    end
  end
end
