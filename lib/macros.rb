module Atomy::Macro
  module Helpers
    # generate symbols
    def names(num = 0, &block)
      num = block.arity if block

      as = []
      num.times do
        as << variable(
          "s:" + Atomy::Macro::Environment.salt!.to_s
        )
      end

      if block
        block.call(*as)
      else
        as
      end
    end
  end

  class Environment
    @@salt = 0
    @@macros = {}
    @@let = {}
    @@line = 0

    class << self
      def let
        @@let
      end

      def line
        @@line
      end

      def line=(x)
        @@line = x
      end

      def salt
        @@salt
      end

      def salt!(n = 1)
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

    name = let ? :"_let#{Environment.salt!}" : :_expand

    Atomy.define_method(
      target,
      name,
      pattern,
      Atomy::AST::Send.new(
        body.line,
        Atomy::AST::Variable.new(body.line, "expand"),
        body.recursively(&:resolve),
        [],
        nil,
        "expand"
      ),
      [],
      Rubinius::StaticScope.new(Atomy::AST),
      :public,
      file,
      pattern.expression.line
    )

    if let
      Environment.let[target] ||= []
      Environment.let[target] << name
    end

    name
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
