module Atomo
  module AST
    class Metaclass < Node
      children :receiver, :body
      generate

      def sclass_body
        Rubinius::AST::SClassScope.new @line, @body
      end

      def bytecode(g)
        pos(g)
        @receiver.bytecode(g)
        sclass_body.bytecode(g)
      end
    end
  end
end
