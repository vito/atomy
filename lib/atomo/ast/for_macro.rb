module Atomo
  module AST
    class ForMacro < Node
      Atomo::Parser.register self

      def self.rule_name
        "for_macro"
      end

      def initialize(body)
        @body = body
        @line = 1 # TODO
      end

      def ==(b)
        b.kind_of?(ForMacro) and \
        @body == b.body
      end

      attr_reader :body

      def construct(g, d)
        get(g)
        @body.construct(g, d)
        g.send :new, 2
      end

      # TODO: if #recursively is defined, see stages.rb;
      # not sure if Pragmas should look through their bodies.

      def self.grammar(g)
        g.for_macro =
          g.seq(
            "for-macro", :sig_sp, g.t(:expression)
          ) do |b|
            ForMacro.new(b)
          end
      end

      def bytecode(g)
        pos(g)
        g.push_nil
      end
    end
  end
end
