module Atomy
  module Code
    class StringLiteral
      ESCAPES = {
        "n" => "\n", "s" => "\s", "r" => "\r", "t" => "\t", "v" => "\v",
        "f" => "\f", "b" => "\b", "a" => "\a", "e" => "\e", "\\" => "\\"
      }

      def initialize(value)
        @value = value
      end

      def bytecode(gen, mod)
        gen.push_literal(process_escapes(@value))
        gen.string_dup
      end

      private

      def process_escapes(str)
        processed = str.dup

        processed.gsub!(/\\[xX]([0-9a-fA-F]{1,5})/) do
          [$1.to_i(16)].pack("U")
        end

        processed.gsub!(/\\(\d{1,6})/) do
          [$1.to_i].pack("U")
        end

        processed.gsub!(/\\[oO]([0-7]{1,7})/) do
          [$1.to_i(8)].pack("U")
        end

        processed.gsub!(/\\[uU]([0-9a-fA-F]{4})/) do
          [$1.to_i(16)].pack("U")
        end

        processed.gsub!(/\\(.)/) do
          ESCAPES[$1] || "\\#$1"
        end

        processed
      end
    end
  end
end
