class MethodFail < ArgumentError
  def initialize(mn)
    @method_name = mn
  end

  def message
    "method #{@method_name.to_s} did not understand " +
      "its arguments (non-exhaustive patterns)"
  end
end

module Atomy
  OPERATORS = {}
  STATE = {}

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
      @@macros = {}
      @@let = Hash.new { |h, k| h[k] = [] }
      @@quoters = {}
      @@line = 0

      class << self
        attr_accessor :quoters

        def macros
          @@macros
        end

        def let
          @@let
        end

        def line
          @@line
        end

        def line=(x)
          @@line = x
        end

        def quoter(name, &blk)
          @@quoters[name] = blk
        end

        def quote(name, contents, flags, value = nil)
          if a = @@quoters[name.to_sym]
            a.call(contents, flags, value)
          else
            raise "unknown quoter #{name.inspect}"
          end
        end

        def names(num = 0, &block)
          num = block.arity if block

          as = []
          num.times do
            as << Atomy::AST::Variable.new(0, "s:" + @@salt.to_s)
            @@salt += 1
          end

          if block
            block.call(*as)
          else
            as
          end
        end
      end
    end

    def self.register(name, args, body, let = false)
      ns = Atomy::Namespace.get(Thread.current[:atomy_define_in])
      meth = ns ? Atomy.namespaced(ns.name, name) : name
      meth = (intern meth).to_sym

      if let && Environment.respond_to?(meth)
        Environment.let[name] << Environment.method(meth)
      end

      methods = Environment.macros
      method = [[Patterns::Any.new, args], body.resolve]
      if ms = methods[meth]
        Atomy.insert_method(method, ms)
      else
        methods[meth] = [method]
      end

      Atomy.add_method(
        Environment.singleton_class,
        meth,
        methods[meth],
        nil,
        :public,
        true
      )

      meth
    end

    def self.intern(name)
      "atomy-macro:" + name
    end

    # take a node and return its expansion
    def self.expand(node)
      name = node.method_name

      return node unless name

      methods = []
      if name && ns = Atomy::Namespace.get
        ([ns.name] + ns.using).each do |n|
          methods << intern(Atomy.namespaced(n, name)).to_sym
        end
      end

      methods << intern(name).to_sym

      expanded = nil
      methods.each do |meth|
        next unless Environment.respond_to?(meth)

        expanded = expand_node(node, meth)
        break if expanded
      end

      expanded || node
    end

    def self.expand_node(node, meth)
      Environment.line ||= node.line

      begin
        case node
        when AST::BinarySend
          expand_res Environment.send(
            meth,
            nil,
            node.lhs,
            node.rhs
          )
        when AST::Send
          if node.arguments.last.kind_of?(AST::Unary) && \
              node.arguments.last.operator == "&"
            block = AST::BlockPass.new(node.line, node.arguments.pop.receiver)
          else
            block = node.block
          end

          expand_res Environment.send(
            meth,
            block,
            node.receiver,
            *node.arguments
          )
        when AST::Unary
          expand_res Environment.send(
            meth,
            nil,
            node.receiver
          )
        when AST::Variable
          expand_res Environment.send(
            meth
          )
        else
          # just stopping
          nil
        end
      rescue MethodFail, ArgumentError => e
        # expand normally if the macro doesn't seem to be a match
        raise unless e.instance_variable_get("@method_name") == meth
        nil
      ensure
        Environment.line = nil
      end
    end

    # helper method for #expand
    def self.expand_res(node)
      expand(node.to_node)
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

        if x.receiver.kind_of?(Atomy::AST::Send) && !x.receiver.block
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
          if Atomy::AST.constants.include? sub.identifier
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
              sub.identifier
            )
          else
            sub
          end
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
