module Atomy
  module AST
    class Constant < Node
      attributes :identifier
      generate

      def name
        @identifier.to_sym
      end

      def bytecode(g)
        pos(g)
        g.push_const name
      end

      def assign(g, v)
        g.push_scope
        g.push_literal name
        v.compile(g)
        g.send :const_set, 2
      end

      def as_message(send)
        send.dup.tap do |s|
          s.method_name = @identifier
        end
      end
    end

    class ToplevelConstant < Node
      attributes :identifier
      generate

      def name
        @identifier.to_sym
      end

      def bytecode(g)
        pos(g)
        g.push_cpath_top
        g.find_const name
      end

      def assign(g, v)
        g.push_cpath_top
        g.push_literal name
        v.compile(g)
        g.send :const_set, 2
      end

      def as_message(send)
        send.dup.tap do |s|
          s.method_name = @identifier
        end
      end
    end

    class ScopedConstant < Node
      children :parent
      attributes :identifier
      generate

      def name
        @identifier.to_sym
      end

      def bytecode(g)
        pos(g)
        @parent.compile(g)
        g.find_const name
      end

      def assign(g, v)
        @parent.compile(g)
        g.push_literal name
        v.compile(g)
        g.send :const_set, 2
      end

      def as_message(send)
        send.dup.tap do |s|
          s.method_name = @identifier
          s.receiver = @parent
        end
      end
    end
  end
end
