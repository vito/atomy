module Atomy
  module AST
    class While < Rubinius::AST::While
      include NodeLike
      extend SentientNode

      children :condition, :body
      attributes [:check_first, true]
      generate
    end
  end
end
