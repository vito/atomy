module Atomy
  class Compiler < Rubinius::Compiler
    attr_accessor :expander

    def self.compiled_name(file)
      if file.suffix? ".ay"
        file + "c"
      else
        file + ".compiled.ayc"
      end
    end

    def self.compile(file, output = nil, debug = false)
      compiler = new :atomy_file, :compiled_file

      compiler.parser.root Atomy::AST::Script
      compiler.parser.input file, 1

      compiler.packager.print.bytecode = debug if debug

      compiler.writer.name = output ? output : compiled_name(file)

      compiler.run
    end

    def self.compile_file(file, debug = false)
      compiler = new :atomy_file, :compiled_method

      compiler.parser.root Atomy::AST::Script
      compiler.parser.input file, 1

      compiler.packager.print.bytecode = debug if debug

      compiler.run
    end

    def self.compile_string(string,
                            file = "(eval)", line = 1, debug = false)
      compiler = new :atomy_string, :compiled_method

      compiler.parser.root Atomy::AST::Script
      compiler.parser.input string, file, line

      compiler.packager.print.bytecode = debug if debug

      compiler.run
    end

    def self.compile_eval(string, scope = nil,
                          file = "(eval)", line = 1, debug = false)
      compiler = new :atomy_string, :compiled_method

      compiler.parser.root Rubinius::AST::EvalExpression
      compiler.parser.input string, file, line

      compiler.packager.print.bytecode = debug if debug

      compiler.generator.variable_scope = scope

      compiler.run
    end

    def self.compile_node(node, scope = nil,
                          file = "(eval)", line = 1, debug = false)
      compiler = new :atomy_bytecode, :compiled_method

      expr = Rubinius::AST::EvalExpression.new(AST::Tree.new(line, [node]))
      expr.file = file

      compiler.packager.print.bytecode = debug if debug

      compiler.generator.input expr
      compiler.generator.variable_scope = scope

      compiler.run
    end

    def self.evaluate_node(node, bnd = nil, instance = nil,
                           file = "(eval)", line = 1, debug = false)
      if bnd.nil?
        bnd = Binding.setup(
          Rubinius::VariableScope.of_sender,
          Rubinius::CompiledMethod.of_sender,
          Rubinius::StaticScope.of_sender
        )
      end

      cm = compile_node(node, bnd.variables, file, line)
      cm.scope = bnd.static_scope.dup
      cm.name = :__eval__

      script = Rubinius::CompiledMethod::Script.new(cm, file, true)
      script.eval_binding = bnd

      cm.scope.script = script

      be = Rubinius::BlockEnvironment.new
      be.under_context(bnd.variables, cm)

      if bnd.from_proc?
        be.proc_environment = bnd.proc_environment
      end

      be.from_eval!

      if instance
        be.call_on_instance instance
      else
        be.call
      end
    end

    def self.evaluate(string, bnd = nil, instance = nil,
                      file = "(eval)", line = 1, debug = false)
      if bnd.nil?
        bnd = Binding.setup(
          Rubinius::VariableScope.of_sender,
          Rubinius::CompiledMethod.of_sender,
          Rubinius::StaticScope.of_sender
        )
      end

      cm = compile_eval(string, bnd.variables, file, line, debug)
      cm.scope = bnd.static_scope.dup
      cm.name = :__eval__

      script = Rubinius::CompiledMethod::Script.new(cm, file, true)
      script.eval_binding = bnd
      script.eval_source = string

      cm.scope.script = script

      be = Rubinius::BlockEnvironment.new
      be.under_context(bnd.variables, cm)

      if bnd.from_proc?
        be.proc_environment = bnd.proc_environment
      end

      be.from_eval!

      if instance
        be.call_on_instance instance
      else
        be.call
      end
    end
  end
end
