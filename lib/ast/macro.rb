module Atomy
  module AST
    class Macro < Node
      children :pattern, :body
      generate

      def bytecode(g)
        # register macro during compilation too.
        @pattern.register_macro @body

        done = g.new_label
        skip = g.new_label

        g.push_cpath_top
        g.find_const :Atomy
        g.find_const :CodeLoader
        g.send :compiled?, 0
        g.git skip

        load_bytecode(g)
        g.goto done

        skip.set!
        g.push_nil

        done.set!
      end

      def load_bytecode(g)
        pos(g)
        @pattern.construct(g)
        @body.construct(g)
        g.send :register_macro, 1
      end
    end
  end
end
