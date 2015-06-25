require "atomy/code/pattern"

require "atomy/node/meta"


class Atomy::Code::Pattern
  class Wildcard < self
    def initialize(name = nil, set = false)
      @name = name
      @set = set
    end

    def bytecode(gen, mod)
      gen.push_cpath_top
      gen.find_const(:Atomy)
      gen.find_const(:Pattern)
      gen.find_const(:Wildcard)
      gen.send(:new, 0)
    end

    def assign(gen)
      assignment_local(gen, @name, @set).set_bytecode(gen)
    end

    private

    def assignment_local(gen, name, set = false)
      var = gen.state.scope.search_local(name)

      if var && (set || var.depth == 0)
        var
      else
        gen.state.scope.new_local(name).nested_reference
      end
    end
  end
end
