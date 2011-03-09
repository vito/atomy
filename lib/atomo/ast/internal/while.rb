module Atomo
  module AST
    class While < Rubinius::AST::While
      include NodeLike
      extend SentientNode

      children :condition, :body
      attributes [:check_first, false]
      generate
    end
  end
end
