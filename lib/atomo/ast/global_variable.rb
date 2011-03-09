module Atomo
  module AST
    class GlobalVariable < Node
      attributes :name
      generate

      def bytecode(g)
        pos(g)
        g.push_rubinius
        g.find_const :Globals
        g.push_literal(("$" + @name).to_sym)
        g.send :[], 1
      end
    end
  end
end
