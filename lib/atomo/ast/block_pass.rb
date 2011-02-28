module Atomo
  module AST
    class BlockPass < Rubinius::AST::BlockPass
      include NodeLike

      attr_reader :name

      def initialize(body)
        super(1, body) # TODO
      end

      def ==(b)
        b.kind_of?(BlockPass) and \
        @body == b.body
      end
    end
  end
end
