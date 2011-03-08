module Atomo
  module AST
    class Constant < Node
      attr_reader :name

      def initialize(line, name)
        @line = line
        @name = name.to_sym
      end

      def construct(g, d = nil)
        get(g)
        g.push_int @line
        g.push_literal @name
        g.send :new, 2
      end

      def ==(b)
        b.kind_of?(Constant) and \
          @name == b.name
      end

      def bytecode(g)
        pos(g)
        g.push_const @name
      end

      def assign(g, v)
        g.push_scope
        g.push_literal @name
        v.bytecode(g)
        g.send :const_set, 2
      end
    end

    class ToplevelConstant < Node
      attr_reader :name

      def initialize(line, name)
        @line = line
        @name = name.to_sym
      end

      def construct(g, d = nil)
        get(g)
        g.push_int @line
        g.push_literal @name
        g.send :new, 2
      end

      def ==(b)
        b.kind_of?(ToplevelConstant) and \
          @name == b.name
      end

      def bytecode(g)
        pos(g)
        g.push_cpath_top
        g.find_const @name
      end

      def assign(g, v)
        g.push_cpath_top
        g.push_literal @name
        v.bytecode(g)
        g.send :const_set, 2
      end
    end

    class ScopedConstant < Node
      attr_reader :parent, :name

      def initialize(line, parent, name)
        @line = line
        @parent = parent
        @name = name.to_sym
      end

      def construct(g, d = nil)
        get(g)
        g.push_int @line
        @parent.construct(g, d)
        g.push_literal @name
        g.send :new, 3
      end

      def ==(b)
        b.kind_of?(ScopedConstant) and \
          @name == b.name and \
          @parent == b.parent
      end

      def bytecode(g)
        pos(g)
        @parent.bytecode(g)
        g.find_const @name
      end

      def assign(g, v)
        @parent.bytecode(g)
        g.push_literal @name
        v.bytecode(g)
        g.send :const_set, 2
      end
    end
  end
end
