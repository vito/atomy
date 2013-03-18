require "atomy/grammar"
require "atomy/module"
require "atomy/code/self"
require "atomy/code/send"
require "atomy/code/sequence"
require "atomy/code/string_literal"

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
        end
      end

      node
    end
  end
end
