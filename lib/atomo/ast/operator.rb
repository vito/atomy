base = File.expand_path "../../", __FILE__

require base + '/patterns'

module Atomo
  module AST
    class Operator < AST::Node
      Atomo::Parser.register self

      def self.rule_name
        "operator"
      end

      def initialize(operator, lhs, rhs)
        @operator = operator
        @lhs = lhs
        @rhs = rhs
        @line = 1 # TODO
      end

      attr_reader :operator, :lhs, :rhs

      def self.grammar(g)
        g.operators = g.t(/((?![,;])[!@#%&*-.\/\?:\p{S}])+/u)
        g.operator =
          g.seq(
            :operator, :sp, :operators, :sp, :expression
          ) do |l, _, o, _, r|
            Operator.new(o,l,r)
          end | g.seq(
            :level3, :sp, :operators, :sp, :expression
          ) do |l, _, o, _, r|
            Operator.new(o,l,r)
          end | g.seq(
            :operators, :sp, :expression
          ) do |o, _, r|
            Operator.new(o, Self.new, r)
          end
      end

      def bytecode(g)
        pos(g)

        if @operator == "="
          pat = Atomo::Pattern::from_node(@lhs)
          @rhs.bytecode(g)
          pat.match(g)
          return
        elsif @operator == ":="
          recv = Atomo::Pattern::from_node(@lhs.receiver)
          if @lhs.respond_to? :arguments
            args = @lhs.arguments.each do |a|
              Atomo::Pattern::from_node(a)
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
