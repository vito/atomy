module Atomy
  module AST
    class Variable < Node
      attributes :name
      slots :namespace?
      generate

      def self.new(*as)
        x = super
        unless x.namespace
          x.namespace, x.name = Atomy.from_namespaced(x.name)
        end
        x
      end

      def register_macro(body, let = false)
        Atomy::Macro.register(
          method_name,
          [],
          body,
          let
        )
      end

      def prepare
        resolve.expand
      end

      def message_name
        Atomy.namespaced(@namespace, @name)
      end

      def bytecode(g)
        pos(g)

        var = g.state.scope.search_local(@name)
        if var
          var.get_bytecode(g)
        else
          g.push_self
          g.push_literal message_name.to_sym
          g.send :atomy_send, 1
          #g.call_custom message_name.to_sym, 0
        end
      end

      # used in macroexpansion
      def method_name
        name + ":@"
      end

      def namespace_symbol
        name.to_sym
      end

      def as_message(send)
        send.dup.tap do |s|
          s.method_name = @name
          s.namespace = @namespace
        end
      end
    end
  end
end
