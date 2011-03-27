class MethodFail < ArgumentError
  def initialize(mn)
    @method_name = mn
  end

  def message
    "method #{@method_name} did not understand " +
      "its arguments (non-exhaustive patterns)"
  end
end

module Atomy
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

      attr_accessor :macros, :quoters, :line

      def initialize
        @macros = {}
        @quoters = {}
        @line = 0
      end

      def quoter(name, &blk)
        @quoters[name] = blk
      end

      def quote(name, contents, flags)
        if a = @quoters[name.to_sym]
          a.call(contents, flags)
        else
          raise "unknown quoter #{name.inspect}"
        end
      end

      def names(&block)
        as = []
        block.arity.times do
          as << Atomy::AST::Variable.new(0, "s:" + @@salt.to_s)
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
        Atomy.insert_method(method, ms)
      else
        methods[name] = [method]
      end

      Atomy.add_method(CURRENT_ENV.metaclass, name, methods[name], nil, :public, true)
    end

    def self.expand?(node)
      case node
      when AST::BinarySend, AST::Send, AST::Unary,
           AST::MacroQuote, AST::Variable, AST::Macro
        true
      else
        false
      end
    end

    def self.intern(name)
      "atomy_macro::" + name
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
      when AST::Send
        AST::Send.new(
          node.line,
          expand(node.receiver),
          node.arguments.collect { |a| expand(a) },
          node.method_name,
          node.block ? expand(node.block) : node.block,
          node.private
        )
      when AST::Unary
        AST::Unary.new(
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

        CURRENT_ENV.line ||= node.line

        begin
          case node
          when AST::BinarySend
            expand CURRENT_ENV.send(
              (intern name).to_sym,
              nil,
              node.lhs,
              node.rhs
            ).to_node
          when AST::Send
            expand CURRENT_ENV.send(
              (intern name).to_sym,
              node.block,
              node.receiver,
              *node.arguments
            ).to_node
          when AST::Unary
            expand CURRENT_ENV.send(
              (intern name).to_sym,
              nil,
              node.receiver
            ).to_node
          when AST::Variable
            expand CURRENT_ENV.send(
              (intern name).to_sym
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
        ensure
          CURRENT_ENV.line = nil
        end
      end
    end

    # @!x
    #  to:
    # @`(!~x)
    #
    # @!?x
    #  to:
    # @(`!?~x)
    def self.unary_chain(n)
      d = n.dup
      x = d
      while x.kind_of?(Atomy::AST::Unary)
        if x.receiver.kind_of?(Atomy::AST::Unary)
          y = x.receiver.dup
          x.receiver = y
          x = y
        else
          unless x.receiver.kind_of?(Atomy::AST::Primitive)
            x.receiver = Atomy::AST::Unquote.new(
              x.receiver.line,
              x.receiver
            )
          end
          break
        end
      end

      Atomy::AST::QuasiQuote.new(d.line, d)
    end

    # x(a) y(b)
    #  to:
    # `(x(~a)) y(b)
    #
    # x(a) y(b) z(c)
    #  to:
    # `(x(~a) y(~b)) z(c)
    #
    # x(&a) b(c) should bind the proc-arg
    def self.send_chain(n)
      return n if n.block

      d = n.dup
      x = d
      while x.kind_of?(Atomy::AST::Send)
        if n.block
          next
        end

        as = []
        x.arguments.each do |a|
          if a.kind_of?(Atomy::AST::Unary) && a.operator == "&"
            x.block = Atomy::AST::Unquote.new(
              a.line,
              a.receiver
            )
          else
            as << Atomy::AST::Unquote.new(
              a.line,
              a
            )
          end
        end

        x.arguments = as

        if x.receiver.kind_of?(Atomy::AST::Send)
          y = x.receiver.dup
          x.receiver = y
          x = y
        else
          unless x.receiver.kind_of?(Atomy::AST::Primitive)
            x.receiver = Atomy::AST::Unquote.new(
              x.receiver.line,
              x.receiver
            )
          end
          break
        end
      end

      Atomy::AST::QuasiQuote.new(d.line, d)
    end

    def self.macro_pattern(n)
      if n.kind_of?(Atomy::AST::Send) && !n.block
        n = send_chain(n)
      end

      if n.kind_of?(Atomy::AST::Unary) && n.operator != "&" && n.operator != "*"
        n = unary_chain(n)
      end

      n = n.recursively do |sub|
        case sub
        when Atomy::AST::Constant
          Atomy::AST::ScopedConstant.new(
            sub.line,
            Atomy::AST::ScopedConstant.new(
              sub.line,
              Atomy::AST::Constant.new(
                sub.line,
                "Atomy"
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
      when Atomy::AST::Primitive
        if n.value == :self
          Atomy::Patterns::Quote.new(
            Atomy::AST::Primitive.new(n.line, :self)
          )
        else
          n.to_pattern
        end
      else
        n.to_pattern
      end
    end
  end
end
