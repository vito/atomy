module Atomo
  module AST
    class Constant < Node
      attributes :name
      generate

      def name
        @name.to_sym
      end

      def bytecode(g)
        pos(g)
        g.push_const name
      end

      def assign(g, v)
        g.push_scope
        g.push_literal name
        v.bytecode(g)
        g.send :const_set, 2
      end
    end

    class ToplevelConstant < Node
      attributes :name
      generate

      def name
        @name.to_sym
      end

      def bytecode(g)
        pos(g)
        g.push_cpath_top
        g.find_const name
      end

      def assign(g, v)
        g.push_cpath_top
        g.push_literal name
        v.bytecode(g)
        g.send :const_set, 2
      end
    end

    class ScopedConstant < Node
      children :parent
      attributes :name
      generate

      def name
        @name.to_sym
      end

      def bytecode(g)
        pos(g)
        @parent.bytecode(g)
        g.find_const name
      end

      def assign(g, v)
        @parent.bytecode(g)
        g.push_literal name
        v.bytecode(g)
        g.send :const_set, 2
      end
    end
  end
end
