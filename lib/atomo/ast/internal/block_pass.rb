module Atomo
  module AST
    class BlockPass < Rubinius::AST::BlockPass
      include NodeLike
      extend SentientNode

      children :body
      generate
    end
  end
end
