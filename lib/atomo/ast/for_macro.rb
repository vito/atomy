module Atomo
  module AST
    class ForMacro < Node
      children :body
      generate

      def bytecode(g)
        pos(g)
        g.push_const :Atomo
        g.find_const :Compiler
        @body.construct(g, nil)
        g.push_const :Atomo
        g.find_const :Macro
        g.find_const :CURRENT_ENV
        g.send :evaluate_node, 2
      end
    end
  end
end
