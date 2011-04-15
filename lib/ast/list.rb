module Atomy
  module AST
    class List < Node
      children [:elements]
      generate

      def as_message(send)
        send.dup.tap do |s|
          s.arguments = @elements
          s.method_name = "[]"
        end
      end

      def bytecode(g)
        pos(g)

        @elements.each do |e|
          e.compile(g)
        end

        g.make_array @elements.size
      end
    end
  end
end
