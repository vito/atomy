module Atomy::Macro
  class Environment
    @@salt = 0
    @@macros = {}
    @@let = {}
    @@quoters = {}
    @@line = 0

    class << self
      attr_accessor :quoters

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

      def salt
        @@salt
      end

      def salt!(n)
        @@salt += n
      end
    end
  end

  def self.intern(name, let_num = nil)
    "atomy-macro#{let_num ? "-let-#{let_num}" : ""}:" + name
  end

  def self.register(target, pattern, body, file = :macro, let = false)
    #ns = Atomy::Namespace.get(Thread.current[:atomy_define_in])
    #meth = !let && ns ? Atomy.namespaced(ns.name, name) : name

    #if let
      #Environment.let[name] ||= []
      #meth = (intern meth, Environment.let[name].size).to_sym
      #Environment.let[name] << meth
    #else
      #meth = (intern meth).to_sym
    #end

    Atomy.define_method(
      target,
      :_expand,
      pattern,
      body.recursively(&:resolve),
      [],
      Rubinius::StaticScope.new(Atomy::AST),
      :public,
      file,
      pattern.expression.line
    )
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
              Atomy::AST::ToplevelConstant.new(
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
