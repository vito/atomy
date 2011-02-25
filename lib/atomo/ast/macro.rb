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

      def construct(g, d)
        get(g)
        g.push_literal @pattern
        @body.construct(g, d)
        g.send :new, 2
      end

      # TODO: if #recursively? is defined, see stages.rb;
      # not sure if Pragmas should look through their bodies.

      def self.grammar(g)
        g.macro =
          g.seq(
            "macro", :sig_sp,
            "(", :sp, g.t(:expression), :sp, ")",
            :sp, g.t(:expression)
          ) do |p, b|
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
