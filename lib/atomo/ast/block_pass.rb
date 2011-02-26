module Atomo
  module AST
    class BlockPass < Rubinius::AST::BlockPass
      include NodeLike

      Atomo::Parser.register self

      def self.rule_name
        "block_pass"
      end

      def initialize(body)
        super(1, body) # TODO
      end

      def ==(b)
        b.kind_of?(BlockPass) && @body == b.body
      end

      attr_reader :name

      def self.grammar(g)
        g.block_pass =
          g.seq("&", g.t(:level1)) { |x| BlockPass.new(x) }
      end
    end
  end
end
