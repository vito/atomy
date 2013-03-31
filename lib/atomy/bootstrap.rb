require "atomy/grammar"
require "atomy/module"
require "atomy/code/assign"
require "atomy/code/integer"
require "atomy/code/quote"
require "atomy/code/self"
require "atomy/code/send"
require "atomy/code/sequence"
require "atomy/code/string_literal"
require "atomy/code/variable"
require "atomy/pattern/equality"
require "atomy/pattern/quasi_quote"
require "atomy/pattern/splat"
require "atomy/pattern/wildcard"

module Atomy
  Bootstrap = Atomy::Module.new do
    def expand(node)
      case node
      when Atomy::Grammar::AST::Apply
        if node.node.is_a?(Atomy::Grammar::AST::Word)
          return Code::Send.new(nil, node.node.text, node.arguments)
        end
      when Atomy::Grammar::AST::StringLiteral
        return Code::StringLiteral.new(node.value)
      when Atomy::Grammar::AST::Sequence
        return Code::Sequence.new(node.nodes)
      when Atomy::Grammar::AST::Word
        case node.text
        when :self
          return Code::Self.new
        else
          return Code::Variable.new(node.text)
        end
      when Atomy::Grammar::AST::Number
        return Code::Integer.new(node.value)
      when Atomy::Grammar::AST::Infix
        if node.operator == :"="
          return Code::Assign.new(node.left, node.right)
        else
          return Code::Send.new(node.left, node.operator, [node.right])
        end
      when Atomy::Grammar::AST::Quote
        return Code::Quote.new(node.node)
      end

      super
    end

    def pattern(node)
      case node
      when Atomy::Grammar::AST::Word
        return Pattern::Wildcard.new(
          node.text == :_ ? nil : node.text)
      when Atomy::Grammar::AST::Number
        return Pattern::Equality.new(node.value)
      when Atomy::Grammar::AST::Quote
        return Pattern::Equality.new(node.node)
      when Atomy::Grammar::AST::QuasiQuote
        return Pattern::QuasiQuote.make(self, node.node)
      when Atomy::Grammar::AST::Prefix
        if node.operator == :*
          return Pattern::Splat.new(pattern(node.node))
        end
      end

      super
    end
  end
end
