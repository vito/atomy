require "atomy/grammar"
require "atomy/code/send"
require "atomy/code/string_literal"

module Atomy
  module Bootstrap
    def expand(node)
      case node
      when Atomy::Grammar::AST::Apply
        if node.node.is_a?(Atomy::Grammar::AST::Word)
          return Send.new(nil, node.node.text, node.arguments)
        end
      when Atomy::Grammar::AST::StringLiteral
        return StringLiteral.new(node.value)
      end

      node
    end
  end
end
