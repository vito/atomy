module Atomo
  class Compiler
    class Generator < Rubinius::Compiler::Stage
      stage :atomo_bytecode
      next_stage Rubinius::Compiler::Encoder

      attr_accessor :variable_scope

      def initialize(compiler, last)
        super
        @variable_scope = nil
        compiler.generator = self
      end

      def run
        @output = Rubinius::Generator.new
        @input.variable_scope = @variable_scope
        @input.bytecode @output
        @output.close
        run_next
      end

      def input(root)
        @input = root
      end
    end

    class MacroExpander < Rubinius::Compiler::Stage
      stage :atomo_expand
      next_stage Generator

      def initialize(compiler, last)
        super
        compiler.expander = self
      end

      def input(root, file = "(eval)", line = 1)
        @input = root
        @file = file
        @line = line
      end

      def print
        @print = true
      end

      def run
        @output = @input.dup
        @output.body = @input.body.collect do |n|
          Atomo::Macro.expand(n)
        end
        run_next
      end
    end

    class Parser < Rubinius::Compiler::Stage
      stage :atomo_parser
      next_stage MacroExpander

      def initialize(compiler, last)
        super
        compiler.parser = self
      end

      def root(root)
        @root = root
      end

      def print
        @print = true
      end

      def input(code, file = "(eval)", line = 1)
        @input = code
        @file = file
        @line = line
      end

      def run
        @output = @root.new parse
        @output.file = @file
        run_next
      end
    end

    class FileParser < Parser
      stage :atomo_file
      next_stage MacroExpander

      def input(file, line = 1)
        @file = file
        @line = line
      end

      def parse
        Atomo::Parser.parse_file(@file)
      end
    end

    class StringParser < Parser
      stage :atomo_string
      next_stage MacroExpander

      def parse
        Atomo::Parser.parse_string(@input)
      end
    end
  end
end