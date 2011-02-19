module Atomo
  module AST
    class UnarySend < AST::Node
      Atomo::Parser.register self

      def self.rule_name
        "unary_send"
      end

      def initialize(receiver, method)
        @receiver = receiver
        @method_name = method
        @line = 1 # TODO
      end

      attr_reader :receiver, :method_name

      def self.grammar(g)
        g.unary_send =
          g.seq(
            :unary_send, :sig_sp, :method_name, g.notp(":")
          ) do |v, _, n|
            UnarySend.new(v,n)
          end | g.seq(
            :level1, :sig_sp, :method_name, g.notp(":")
          ) do |v, _, n|
            UnarySend.new(v,n)
          end
      end

      def bytecode(g)
        pos(g)
        @receiver.bytecode(g)
        g.send @method_name.to_sym, 0
        # g.call_custom @method_name.to_sym, 0
      end
    end
  end
end
