module Atomy::Macro
  class Environment
    @@salt = 0
    @@let = {}

    class << self
      def let
        @@let
      end

      def salt
        @@salt
      end

      def salt!(n = 1)
        @@salt += n
      end
    end
  end

  def self.register(target, pattern, body, file = :macro, let = false)
    name = let ? :"_let#{Environment.salt!}" : :_expand

    Atomy::AST::Define.new(
      0,
      Atomy::AST::Compose.new(
        0,
        pattern.quoted,
        Atomy::AST::Word.new(0, name)
      ),
      Atomy::AST::Send.new(
        body.line,
        Atomy::AST::Send.new(
          body.line,
          body,
          [],
          :to_node
        ),
        [],
        :expand
      )
    ).evaluate(
      Binding.setup(
        TOPLEVEL_BINDING.variables,
        TOPLEVEL_BINDING.code,
        Rubinius::StaticScope.new(Atomy::AST)
      ), file.to_s, pattern.quoted.line
    )

    if let
      Environment.let[target] ||= []
      Environment.let[target] << name
    end

    name
  end
end
