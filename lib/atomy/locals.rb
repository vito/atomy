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

  class EvalLocalState < LocalState
    def initialize(variable_scope)
      @variable_scope = variable_scope
    end

    # Returns a cached reference to a variable or searches all
    # surrounding scopes for a variable. If no variable is found,
    # it returns nil and a nested scope will create the variable
    # in itself.
    def search_local(name)
      if variable = variables[name]
        return variable.nested_reference
      end

      if variable = search_scopes(name)
        variables[name] = variable
        return variable.nested_reference
      end
    end

    def new_local(name)
      variable = Rubinius::Compiler::EvalLocalVariable.new(name)
      variables[name] = variable
    end

    private

    def search_scopes(name)
      depth = 1
      scope = @variable_scope

      while scope
        if !scope.method.for_eval? && (slot = scope.method.local_slot(name))
          return Rubinius::Compiler::NestedLocalVariable.new(depth, slot)
        elsif scope.eval_local_defined?(name, false)
          return Rubinius::Compiler::EvalLocalVariable.new(name)
        end

        depth += 1
        scope = scope.parent
      end
    end
  end
end
