module Atomo
  module AST
    class String < AST::Node
      Atomo::Parser.register self

      def self.rule_name
        "string"
      end

      def initialize(value)
        @value = value
        @line = 1 # TODO
      end

      def ==(b)
        b.kind_of?(String) and \
        @value == b.value
      end

      attr_reader :value

      def self.ary(x)
        x.split("")
      end

      def self.grammar(g)
        # TODO: control and meta escapes
        escapes = [
          # Ruby
          ary("nsrtvfbae").zip(ary "\n\s\r\t\v\f\b\a\e"),

          # Haskell
          ary("abfnrtv\\\"").zip(ary "\a\b\f\n\r\t\v\\\""),

          ["BS", "HT", "LF", "VT", "FF", "CR", "SO", "SI", "EM",
           "FS","GS","RS","US","SP"].zip(
            ary "\b\t\n\v\f\r\16\17\31\34\35\36\37"
          ),

          ["NUL", "SOH", "STX", "ETX", "EOT", "ENQ", "ACK", "BEL",
           "DLE", "DC1", "DC2", "DC3", "DC4", "NAK", "SYN", "ETB",
           "CAN", "SUB", "ESC", "DEL"].zip(
            ary "\0\1\2\3\4\5\6\7\20\21\22\23\24\25\26\27\30\32\33\177"
          )
        ].flatten(1).collect do |x, c|
          g.str('\\' + x) { c }
        end

        escape = g.any(
          g.seq('\\x', g.t(/[0-9a-fA-F]{1,5}/)) { |x| x.to_i(16).chr },
          g.seq('\\', g.t(/[0-9]{1,6}/)) { |x| x.to_i.chr },
          g.seq('\\o', g.t(/[0-7]{1,7}/)) { |x| x.to_i(8).chr },
          g.seq('\\', g.t(/[0-9a-fA-F]{4}/)) { |x| x.to_i(16).chr },
          *escapes
        )

        not_quote = g.many(g.any(escape, /[^"]/)) { |*a| a.join }
        g.string = g.seq("\"", g.t(not_quote), "\"") do |str|
          String.new(str)
        end
      end

      def bytecode(g)
        pos(g)
        g.push_literal @value
        g.string_dup
      end
    end
  end
end
