class MethodFail < ArgumentError
  def initialize(mn)
    @method_name = mn
  end

  def message
    "method #{@method_name} did not understand " +
      "its arguments (non-exhaustive patterns)"
  end
end

module Atomo
  OPERATORS = {}

  module Macro
    def self.set_op_info(ops, assoc, prec)
      ops.each do |o|
        info = OPERATORS[o] ||= {}
        info[:assoc] = assoc
        info[:prec] = prec
      end
    end

    class Environment
      @@salt = 0

      attr_accessor :macros, :quoters

      def initialize
        @macros = {}
        @quoters = {}
      end

      define_method(:"quote:as:") do |name, action|
        @quoters[name] = action
      end

      def quote(name, contents, flags)
        if a = @quoters[name]
          a.call(contents, flags)
        else
          raise "unknown quoter #{name}"
        end
      end

      def names(&block)
        as = []
        block.arity.times do
          as << Atomo::AST::Variable.new(0, "s:" + @@salt.to_s)
          @@salt += 1
        end
        block.call(*as)
      end
    end

    CURRENT_ENV = Environment.new

    def self.register(name, args, body)
      name = (intern name).to_sym
      body = expand(body) # TODO: verify this

      methods = CURRENT_ENV.macros
      method = [[Patterns::Any.new, args], body]
      if ms = methods[name]
        ms << method
      else
        methods[name] = [method]
      end

      Atomo.add_method(CURRENT_ENV.metaclass, name, methods[name], nil, :public, true)
    end

    def self.expand?(node)
      case node
      when AST::BinarySend, AST::UnarySend,
           AST::KeywordSend, AST::UnaryOperator,
           AST::MacroQuote, AST::Macro
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
          expand(node.lhs),
          expand(node.rhs),
          node.operator,
          node.private
        )
      when AST::UnarySend
        AST::UnarySend.new(
          node.line,
          expand(node.receiver),
          node.arguments.collect { |a| expand(a) },
          node.method_name,
          node.block ? expand(node.block) : node.block,
          node.private
        )
      when AST::KeywordSend
        AST::KeywordSend.new(
          node.line,
          expand(node.receiver),
          node.arguments.collect { |a| expand(a) },
          node.names,
          node.private
        )
      when AST::UnaryOperator
        AST::UnaryOperator.new(
          node.line,
          expand(node.receiver),
          node.operator
        )
      else
        node
      end
    end

    # take a node and return its expansion
    def self.expand(root)
      root.through_quotes(proc { |x| expand? x }) do |node|
        name = node.method_name
        unless node.kind_of?(AST::MacroQuote) ||
                name && CURRENT_ENV.respond_to?(intern name)
          next no_macro(node)
        end

        begin
          case node
          when AST::BinarySend
            expand CURRENT_ENV.send(
              (intern name).to_sym,
              nil,
              node.lhs,
              node.rhs
            ).to_node
          when AST::UnarySend
            expand CURRENT_ENV.send(
              (intern name).to_sym,
              node.block,
              node.receiver,
              *node.arguments
            ).to_node
          when AST::KeywordSend
            expand CURRENT_ENV.send(
              (intern name).to_sym,
              nil,
              node.receiver,
              *node.arguments
            ).to_node
          when AST::UnaryOperator
            expand CURRENT_ENV.send(
              (intern name).to_sym,
              nil,
              node.receiver
            ).to_node
          when AST::MacroQuote
            CURRENT_ENV.quote(
              node.name,
              node.contents,
              node.flags
            ).to_node
          else
            # just stopping
            no_macro(node)
          end
        rescue MethodFail, ArgumentError => e
          # expand normally if the macro doesn't seem to be a match
          raise unless e.instance_variable_get("@method_name") == intern(name).to_sym
          no_macro(node)
        end
      end
    end

    def self.macro_pattern(n)
      n = n.recursively do |sub|
        case sub
        when Atomo::AST::Constant
          Atomo::AST::ScopedConstant.new(
            sub.line,
            Atomo::AST::ScopedConstant.new(
              sub.line,
              Atomo::AST::Constant.new(
                sub.line,
                "Atomo"
              ),
              "AST"
            ),
            sub.name
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
