module Atomy
  module AST
    class Constant < Node
      attributes :name

      def bytecode(g, mod)
        pos(g)
        g.push_cpath_top
        g.find_const :Atomy
        g.push_literal @name
        g.push_scope
        g.send :find_const, 2
      end

      def assign(g, mod, v)
        g.push_scope
        g.push_literal @name
        mod.compile(g, v)
        g.send :const_set, 2
      end
    end

    class ToplevelConstant < Node
      attributes :name

      def bytecode(g, mod)
        pos(g)
        g.push_cpath_top
        g.find_const @name
      end

      def assign(g, mod, v)
        g.push_cpath_top
        g.push_literal @name
        mod.compile(g, v)
        g.send :const_set, 2
      end
    end

    class ScopedConstant < Node
      children :parent
      attributes :name

      def bytecode(g, mod)
        pos(g)
        mod.compile(g, @parent)
        g.find_const @name
      end

      def assign(g, mod, v)
        mod.compile(g, @parent)
        g.push_literal @name
        mod.compile(g, v)
        g.send :const_set, 2
      end
    end
  end
end
