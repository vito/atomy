module Atomo
  module AST
    class Variable < Node
      attr_accessor :line
      attr_reader :name

      def initialize(line, name)
        @name = name
        @line = line
      end

      def ==(b)
        b.kind_of?(Variable) and \
        @name == b.name
      end

      def bytecode(g)
        pos(g)

        var = g.state.scope.search_local(@name)
        if var
          var.get_bytecode(g)
        else
          g.push_self
          g.send @name.to_sym, 0, true
        end
      end
    end
  end
end
