module Atomo
  module Macro
    class Environment
      attr_accessor :macros

      def initialize
        @macros = {}
      end
    end

    CURRENT_ENV = Environment.new

    def self.register(name, args, body)
      name = (intern name).to_sym
      body = expand(body) # TODO: verify this

      methods = CURRENT_ENV.macros
      method = [[Patterns::Any.new, args], body.method(:bytecode)]
      if ms = methods[name]
        ms << method
      else
        methods[name] = [method]
      end

      Atomo.add_method(CURRENT_ENV.metaclass, name, methods[name], nil, true)
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

    def self.no_macro(node)
      case node
      when AST::BinarySend
        AST::BinarySend.new(
          node.line,
          node.operator,
          expand(node.lhs),
          expand(node.rhs),
          node.private
        )
      when AST::UnarySend
        AST::UnarySend.new(
          node.line,
          expand(node.receiver),
          node.method_name,
          node.arguments.collect { |a| expand(a) },
          node.block,
          node.private
        )
      when AST::KeywordSend
        AST::KeywordSend.new(
          node.line,
          expand(node.receiver),
          node.method_name,
          node.arguments.collect { |a| expand(a) },
          node.private
        )
      else
        node
      end
    end

    # take a node and return its expansion
    def self.expand(root)
      root.through_quotes(proc { |x| expand? x }) do |node|
        name = node.method_name
        next no_macro(node) unless name and CURRENT_ENV.respond_to?(intern name)

        case node
        when AST::BinarySend
          expand CURRENT_ENV.send(
            (intern node.operator).to_sym,
            nil,
            node.lhs,
            node.rhs
          )
        when AST::UnarySend
          expand CURRENT_ENV.send(
            (intern node.method_name).to_sym,
            node.block,
            node.receiver,
            *node.arguments
          )
        when AST::KeywordSend
          expand CURRENT_ENV.send(
            (intern node.method_name).to_sym,
            nil,
            node.receiver,
            *node.arguments
          )
        else
          # should be impossible
          no_macro(node)
        end
      end
    end

    def self.macro_pattern(n)
      n = n.recursively do |sub|
        case sub
        when Atomo::AST::Constant
          Atomo::AST::Constant.new(
            sub.line,
            ["Atomo", "AST"] + sub.chain
          )
        else
          sub
        end
      end

      case n
      when Atomo::AST::Primitive
        if n.value == :self
          Atomo::Patterns::Quote.new(
            Atomo::AST::Primitive.new(n.line, :self)
          )
        else
          n
        end
      else
        Atomo::Patterns.from_node(n)
      end
    end
  end
end
