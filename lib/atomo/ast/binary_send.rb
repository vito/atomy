base = File.expand_path "../../", __FILE__

require base + '/patterns'

module Atomo
  module AST
    class BinarySend < Node
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

      def recursively(stop = nil, &f)
        return f.call self if stop and stop.call(self)

        f.call BinarySend.new(
          @operator,
          @lhs.recursively(stop, &f),
          @rhs.recursively(stop, &f)
        )
      end

      def construct(g, d)
        get(g)
        g.push_literal @operator
        @lhs.construct(g, d)
        @rhs.construct(g, d)
        g.send :new, 3
      end

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

      def register_macro(body)
        Atomo::Macro.register(
          @operator,
          [@lhs, @rhs].collect do |n|
            Atomo::Macro.macro_pattern n
          end,
          body
        )
      end

      def bytecode(g)
        pos(g)
        @lhs.bytecode(g)
        @rhs.bytecode(g)
        g.send @operator.to_sym, 1
      end
    end
  end
end
