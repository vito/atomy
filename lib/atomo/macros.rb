module Atomo
  module Macro
    # hash from method names to something that can be #call'd
    @macros = {}

    module Environment
    end

    def self.register(name, args, body)
      name = (intern name).to_sym
      body = expand(body) # TODO: verify this

      if ms = @macros[name]
        ms << [[Patterns::Any.new, args], body.method(:bytecode)]
      else
        @macros[name] = [[[Patterns::Any.new, args], body.method(:bytecode)]]
      end

      Atomo.add_method(Environment.metaclass, name, @macros[name], true)
    end

    def self.expand?(node)
      case node
      when AST::BinarySend, AST::UnarySend, AST::KeywordSend
        true
      else
        false
      end
    end

    def self.intern(name)
      "atomo_macro::" + name
    end

    # take a node and return its expansion
    def self.expand(root)
      root.recursively(proc { |x| expand? x }) do |node|
        case node
        when AST::BinarySend
          if Environment.respond_to?(intern node.operator)
            expand Environment.send((intern node.operator).to_sym, nil, node.lhs, node.rhs)
          else
            AST::BinarySend.new(
              node.operator,
              expand(node.lhs),
              expand(node.rhs)
            )
          end
        when AST::UnarySend
          if Environment.respond_to?(intern node.method_name)
            expand Environment.send((intern node.method_name).to_sym, node.block, node.receiver, *node.arguments)
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
          if Environment.respond_to?(intern node.method_name)
            expand Environment.send((intern node.method_name).to_sym, nil, node.receiver, *node.arguments)
          else
            AST::KeywordSend.new(
              expand(node.receiver),
              node.method_name,
              node.arguments.collect { |a| expand(a) }
            )
          end
        else
          node
        end
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
