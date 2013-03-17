require "atomy/grammar"
require "atomy/module"
require "atomy/code/send"
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
      end

      node
    end
  end
end
