module Atomo
  module AST
    class MacroQuote < Node
      attr_reader :name, :contents, :flags

      def initialize(line, name, contents, flags)
        @name = name.to_sym
        @contents = contents
        @flags = flags
        @line = line
      end

      def construct(g, d)
        get(g)
        g.push_int @line
        g.push_literal @name
        g.push_literal @contents
        @flags.each do |f|
          g.push_literal f
        end
        g.make_array @flags.size
        g.send :new, 4
      end

      def ==(b)
        b.kind_of?(MacroQuote) and \
        @name == b.name and \
        @contents == b.contents and \
        @flags == b.flags
      end

      def bytecode(g)
        pos(g)
        g.push_nil
      end
    end
  end
end
