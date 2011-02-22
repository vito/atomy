base = File.expand_path "../../", __FILE__

require base + '/patterns'

module Atomo
  module AST
    class BinarySend < AST::Node
      Atomo::Parser.register self

      def self.rule_name
        "binary_send"
      end

      def initialize(operator, lhs, rhs)
        @operator = operator
        @lhs = lhs
        @rhs = rhs
        @line = 1 # TODO
      end

      attr_reader :operator, :lhs, :rhs

      def self.grammar(g)
        g.binary_send =
          g.seq(
            :binary_send, :sig_sp, :operator, :sig_sp, :expression
          ) do |l, _, o, _, r|
            BinarySend.new(o,l,r)
          end | g.seq(
            :level3, :sig_sp, :operator, :sig_sp, :expression
          ) do |l, _, o, _, r|
            BinarySend.new(o,l,r)
          end | g.seq(
            :operator, :sig_sp, :expression
          ) do |o, _, r|
            BinarySend.new(o, Primitive.new(:self), r)
          end
      end

      def bytecode(g)
        pos(g)

        if @operator == "="
          if @lhs.kind_of? Constant
            g.push_scope
            g.push_literal @lhs.name.to_sym
            @rhs.bytecode(g)
            g.send :const_set, 2
            g.push_const @lhs.name.to_sym
            return
          end

          pat = Patterns.from_node(@lhs)
          @rhs.bytecode(g)
          pat.match(g)
          return
        elsif @operator == ":="
          recv = Patterns.from_node(@lhs.receiver)
          if @lhs.respond_to? :arguments
            args = @lhs.arguments.each do |a|
              Patterns.from_node(a)
            end
          else
            args = []
          end

          Define.new(@lhs.method_name, recv, args, @rhs).bytecode(g)
          return
        elsif @operator == "::"
          @lhs.bytecode(g)
          g.find_const @rhs.name.to_sym
          return
        end

        @lhs.bytecode(g)
        @rhs.bytecode(g)
        g.send @operator.to_sym, 1
      end
    end
  end
end
