module Atomo
  # hash from method names to something that can be #call'd
  # MACROS = {}
  @macros = {}

  module MacroEnvironment
  end

  def self.register_macro(name, args, body)
    name = ("atomo_macro::" + name).to_sym

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
        if MacroEnvironment.respond_to?("atomo_macro::" + node.operator)
          MacroEnvironment.send(("atomo_macro::" + node.operator).to_sym, node.lhs, node.rhs)
        else
          AST::BinarySend.new(
            node.operator,
            expand(node.lhs),
            expand(node.rhs)
          )
        end
      when AST::UnarySend
        if MacroEnvironment.respond_to?("atomo_macro::" + node.method_name)
          MacroEnvironment.send(("atomo_macro::" + node.method_name).to_sym, node.receiver, *node.arguments)
        else
          AST::UnarySend.new(
            expand(node.receiver),
            node.method_name,
            node.arguments.collect { |a| expand(a) },
            node.block,
            node.private
          )
        end
      when AST::KeywordSend
        if MacroEnvironment.respond_to?("atomo_macro::" + node.method_name)
          MacroEnvironment.send(("atomo_macro::" + node.method_name).to_sym, node.receiver, *node.arguments)
        else
          AST::KeywordSend.new(
            expand(node.receiver),
            node.method_name,
            node.arguments.collect { |a| expand(a) }
          )
        end
      else
      # TODO: recurse into other things
        node
      end
    end

    def self.macro_pattern(n)
      n = n.recursively do |sub|
        case sub
        when Atomo::AST::Constant
          Atomo::AST::Constant.new(["Atomo", "AST"] + sub.chain)
        else
          sub
        end
      end

      Atomo::Patterns.from_node(n)
    end
  end
end
