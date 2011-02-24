module Atomo
  # hash from method names to something that can be #call'd
  # MACROS = {}
  @macros = {}

  module MacroEnvironment
  end

  def self.register_macro(name, args, body)
    if ms = @macros[name]
      ms << [[Patterns::Any.new, args], body.method(:bytecode)]
    else
      @macros[name] = [[[Patterns::Any.new, args], body.method(:bytecode)]]
    end

    Atomo.add_method(MacroEnvironment.metaclass, name, @macros[name])
  end

  module Macro
    # take a node and return its expansion
    def self.expand(node)
      case node
      when AST::BinarySend
        p MacroEnvironment.methods - Module.methods
        if MacroEnvironment.respond_to?(node.operator)
          MacroEnvironment.send(node.operator.to_sym, node.lhs, node.rhs)
        else
          AST::BinarySend.new(
            node.operator,
            expand(node.lhs),
            expand(node.rhs)
          )
        end
      else
        node
      end
    end
  end
end