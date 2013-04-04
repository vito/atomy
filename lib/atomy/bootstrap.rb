require "atomy/grammar"
require "atomy/module"
require "atomy/code/assign"
require "atomy/code/define_method"
require "atomy/code/integer"
require "atomy/code/quasi_quote"
require "atomy/code/quote"
require "atomy/code/self"
require "atomy/code/send"
require "atomy/code/sequence"
require "atomy/code/string_literal"
require "atomy/code/variable"
require "atomy/node/meta"
require "atomy/pattern/equality"
require "atomy/pattern/quasi_quote"
require "atomy/pattern/splat"
require "atomy/pattern/wildcard"

module Atomy
  Bootstrap = Atomy::Module.new do
    def expand(node)
      node.accept(NodeExpander.new(self)) || super
    end

    def pattern(node)
      node.accept(PatternExpander.new(self)) || super
    end

    def define_method(name, body, receiver = nil, *arguments)
      code = Atomy::Compiler.package(@file) do |gen|
        Atomy::Code::DefineMethod.new(
          name.text,
          body,
          receiver,
          arguments).bytecode(gen, self)
      end

      bnd =
        Binding.setup(
          Rubinius::VariableScope.of_sender,
          Rubinius::CompiledCode.of_sender,
          Rubinius::ConstantScope.of_sender,
          self)

      block = Atomy::Compiler.construct_block(code, bnd)
      block.call
    end

    private

    class NodeExpander
      def initialize(mod)
        @module = mod
      end

      def visit(_)
        nil
      end

      def visit_apply(node)
        if node.node.is_a?(Atomy::Grammar::AST::Word)
          Code::Send.new(nil, node.node.text, node.arguments)
        end
      end

      def visit_stringliteral(node)
        Code::StringLiteral.new(node.value)
      end

      def visit_sequence(node)
        Code::Sequence.new(node.nodes)
      end

      def visit_word(node)
        case node.text
        when :self
          Code::Self.new
        else
          Code::Variable.new(node.text)
        end
      end

      def visit_number(node)
        Code::Integer.new(node.value)
      end

      def visit_infix(node)
        if node.operator == :"="
          Code::Assign.new(node.left, node.right)
        else
          Code::Send.new(node.left, node.operator, [node.right])
        end
      end

      def visit_quote(node)
        Code::Quote.new(node.node)
      end

      def visit_quasiquote(node)
        Code::QuasiQuote.new(node.node)
      end
    end

    class PatternExpander
      def initialize(mod)
        @module = mod
      end

      def visit(_)
        nil
      end

      def visit_word(node)
        Pattern::Wildcard.new(
          node.text == :_ ? nil : node.text)
      end

      def visit_number(node)
        Pattern::Equality.new(node.value)
      end

      def visit_quote(node)
        Pattern::Equality.new(node.node)
      end

      def visit_quasiquote(node)
        Pattern::QuasiQuote.make(@module, node.node)
      end

      def visit_prefix(node)
        if node.operator == :*
          Pattern::Splat.new(@module.pattern(node.node))
        end
      end
    end
  end
end
