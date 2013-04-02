module Atomy
  class LocalState
    include Rubinius::Compiler::LocalVariables

    attr_accessor :parent

    def search_local(name)
      if variable = variables[name]
        variable.nested_reference
      elsif @parent && reference = @parent.search_local(name)
        reference.depth += 1
        reference
      end
    end

    def new_local(name)
      variable = Rubinius::Compiler::LocalVariable.new(allocate_slot)
      variables[name] = variable
    end
  end
end
