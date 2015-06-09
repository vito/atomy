require "atomy/grammar"
require "atomy/module"
require "atomy/code/assign"
require "atomy/code/block"
require "atomy/code/constant"
require "atomy/code/define_method"
require "atomy/code/define_function"
require "atomy/code/false"
require "atomy/code/instance_variable"
require "atomy/code/integer"
require "atomy/code/list"
require "atomy/code/nil"
require "atomy/code/pattern"
require "atomy/code/quasi_quote"
require "atomy/code/quote"
require "atomy/code/self"
require "atomy/code/send"
require "atomy/code/sequence"
require "atomy/code/string_literal"
require "atomy/code/symbol"
require "atomy/code/true"
require "atomy/code/undefined"
require "atomy/code/variable"
require "atomy/node/meta"
require "atomy/pattern/and"
require "atomy/pattern/equality"
require "atomy/pattern/kind_of"
require "atomy/pattern/quasi_quote"
require "atomy/pattern/splat"
require "atomy/pattern/wildcard"
require "atomy/message_structure"

module Atomy
  Bootstrap = Atomy::Module.new do
    def expand(node)
      node.accept(NodeExpander.new(self)) || super
    end

    def pattern(node)
      node.accept(PatternExpander.new(self)) || super
    end

    def macro_definer(pattern, body)
      BootstrapHelper::WithGrammar.new(Atomy::Code::DefineMethod.new(:expand, body, [pattern]))
    end

    def pattern_definer(pattern, body)
      BootstrapHelper::WithGrammar.new(Atomy::Code::DefineMethod.new(:pattern, body, [pattern]))
    end

    def make_send(recv, msg, args = [])
      Atomy::Code::Send.new(recv, msg.text, args)
    end

    def make_constant(name, parent = nil)
      Atomy::Code::Constant.new(name, parent)
    end

    def make_sequence(nodes)
      Atomy::Grammar::AST::Sequence.new(nodes)
    end

    def make_quasiquote(node)
      Atomy::Grammar::AST::QuasiQuote.new(node)
    end

    private

    class NodeExpander
      def initialize(mod)
        @module = mod
      end

      def visit(node)
        structure = Atomy::MessageStructure.new(node)

        Code::Send.new(
          structure.receiver,
          structure.name,
          structure.arguments,
          structure.splat_argument,
          structure.proc_argument,
          structure.block,
        )
      rescue Atomy::MessageStructure::UnknownMessageStructure
      end

      def visit_stringliteral(node)
        Code::StringLiteral.new(node.value)
      end

      def visit_sequence(node)
        Code::Sequence.new(node.nodes)
      end

      def visit_list(node)
        Code::List.new(node.nodes)
      end

      def visit_word(node)
        case node.text
        when :self
          Code::Self.new
        else
          Code::Variable.new(node.text)
        end
      end

      def visit_constant(node)
        Code::Constant.new(node.text)
      end

      def visit_number(node)
        Code::Integer.new(node.value)
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
        args = []
        locals = []

        if node.text != :_
          args << Code::Symbol.new(node.text)
          locals << node.text
        end

        Code::Pattern.new(
          Code::Send.new(
            Code::Constant.new(
              :Wildcard,
              Code::Constant.new(
                :Pattern,
                Code::Constant.new(:Atomy))),
            :new,
            args),
          locals)
      end

      def visit_number(node)
        Code::Pattern.new(
          Code::Send.new(
            Code::Constant.new(
              :Equality,
              Code::Constant.new(
                :Pattern,
                Code::Constant.new(:Atomy))),
            :new,
            [node]),
          [])
      end

      def visit_quote(node)
        Code::Pattern.new(
          Code::Send.new(
            Code::Constant.new(
              :Equality,
              Code::Constant.new(
                :Pattern,
                Code::Constant.new(:Atomy))),
            :new,
            [node]),
          [])
      end

      def visit_quasiquote(node)
        quoted_patterns, locals =
          Pattern::QuasiQuote.patterns_through(@module, node)

        Code::Pattern.new(
          Code::Send.new(
            Code::Constant.new(
              :QuasiQuote,
              Code::Constant.new(
                :Pattern,
                Code::Constant.new(:Atomy))),
            :new,
            [quoted_patterns]),
          locals)
      end

      def visit_prefix(node)
        if node.operator == :*
          pattern = @module.pattern(node.node)

          Code::Pattern.new(
            Code::Send.new(
              Code::Constant.new(
                :Splat,
                Code::Constant.new(
                  :Pattern,
                  Code::Constant.new(:Atomy))),
              :new,
              [pattern]),
            pattern.locals)
        end
      end

      def visit_infix(node)
        if node.operator == :&
          patterns = [@module.pattern(node.left), @module.pattern(node.right)]

          Code::Pattern.new(
            Code::Send.new(
              Code::Constant.new(
                :And,
                Code::Constant.new(
                  :Pattern,
                  Code::Constant.new(:Atomy))),
              :new,
              patterns),
            patterns.collect(&:locals).flatten)
        end
      end

      def visit_constant(node)
        Code::Pattern.new(
          Code::Send.new(
            Code::Constant.new(
              :KindOf,
              Code::Constant.new(
                :Pattern,
                Code::Constant.new(:Atomy))),
            :new,
            [node]),
          [])
      end
    end
  end

  # helpers that shouldn't be exposed through using Bootstrap
  module BootstrapHelper
    extend self

    class WithGrammar
      def initialize(body)
        @body = body
      end

      def bytecode(gen, mod)
        gen.create_block(build_block(gen.state.scope, mod))
        gen.send(:call, 0)
      end

      private

      def build_block(scope, mod)
        Atomy::Compiler.generate(mod.file) do |blk|
          # close over the outer scope
          blk.state.scope.parent = scope

          # capture original module
          blk.push_scope
          blk.send(:module, 0)

          # add Atomy::Grammar::AST to the constant scope
          blk.push_cpath_top
          blk.find_const(:Atomy)
          blk.find_const(:Grammar)
          blk.find_const(:AST)
          blk.add_scope

          # restore original module for definition targets
          blk.push_scope
          blk.swap
          blk.send(:current_module=, 1)

          mod.compile(blk, @body)
        end
      end
    end
  end
end
