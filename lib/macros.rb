module Atomy::Macro
  module Helpers
    def variable(name, line = 0)
      Atomy::AST::Variable.new(line, name.to_s)
    end

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
        Atomy::AST::Send.new(
          body.line,
          body,
          [],
          "to_node"
        ),
        [],
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
end
