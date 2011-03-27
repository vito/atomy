module Atomo
  module AST
    class Ensure < Rubinius::AST::Ensure
      include NodeLike
      extend SentientNode

      children :body, :ensure
      generate
    end
  end
end
