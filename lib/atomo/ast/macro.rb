module Atomo
  module AST
    class Macro < Node
      Atomo::Parser.register self

      def self.rule_name
        "macro"
      end

      def initialize(pattern, body)
        @pattern = pattern
        @body = body
        @line = 1 # TODO
      end

      attr_reader :pattern, :body

      def self.grammar(g)
        g.macro =
          g.seq(
            "macro", :sig_sp,
            "(", :sp, g.t(:expression), :sp, ")",
            :sp, g.t(:expression)
          ) do |p, b|
            p.register_macro b
            Macro.new(p, b)
          end
      end

      def bytecode(g)
        pos(g)
        g.push_nil
      end
    end
  end
end
