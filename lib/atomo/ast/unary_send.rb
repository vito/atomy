module Atomo
  module AST
    class UnarySend < AST::Node
      Atomo::Parser.register self

      def self.rule_name
        "unary_send"
      end

      def initialize(receiver, method, block = nil)
        @receiver = receiver
        @method_name = method
        @block = block unless block == []
        @line = 1 # TODO
      end

      attr_reader :receiver, :method_name

      def self.grammar(g)
        g.unary_send =
          g.seq(
            :unary_send, :sig_sp, :identifier,
            g.notp(":"), g.maybe(g.seq(:sp, g.t(:block)))
          ) do |v, _, n, _, b|
            UnarySend.new(v, n, b)
          end | g.seq(
            :level1, :sig_sp, :identifier, g.notp(":"),
            g.maybe(g.seq(:sp, g.t(:block)))
          ) do |v, _, n, _, b|
            p b
            UnarySend.new(v, n, b)
          end
      end

      def bytecode(g)
        pos(g)
        @receiver.bytecode(g)

        if @block
          @block.bytecode(g)
          g.send_with_block @method_name.to_sym, 0
        else
          g.send @method_name.to_sym, 0
        end
      end
    end
  end
end
