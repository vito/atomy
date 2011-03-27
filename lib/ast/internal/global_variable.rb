module Atomy
  module AST
    class GlobalVariable < Node
      attributes :identifier
      generate

      def name
        ("$" + @identifier).to_sym
      end

      def bytecode(g)
        pos(g)
        g.push_rubinius
        g.find_const :Globals
        g.push_literal name
        g.send :[], 1
      end
    end
  end
end
