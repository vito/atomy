module Atomo
  def self.add_method(target, name, methods)
    # TODO: arguments
    target.dynamic_method(name) do |g|
      done = g.new_label
      g.push_self
      methods.each do |pat, meth|
        skip = g.new_label

        g.dup
        pat.matches?(g)
        g.gif skip

        g.push_self
        g.send meth, 0
        g.goto done

        skip.set!
      end

      g.push_block
      g.send_super name, 0

      done.set!
      g.ret
    end
  end

  class Compiler < Rubinius::Compiler
    def self.compiled_name(file)
      if file.suffix? ".atomo"
        file + "c"
      else
        file + ".compiled.atomoc"
      end
    end

    def self.compile(file, output = nil, line = 1)
      compiler = new :atomo_file, :compiled_file

      parser = compiler.parser
      parser.root Rubinius::AST::Script
      parser.input file, line

      writer = compiler.writer
      writer.name = output ? output : compiled_name(file)

      compiler.run
    end

    def self.compile_file(file, line = 1)
      compiler = new :atomo_file, :compiled_method

      parser = compiler.parser
      parser.root Rubinius::AST::Script
      parser.input file, line

      compiler.run
    end

    def self.compile_string(string, file = "(eval)", line = 1)
      compiler = new :atomo_string, :compiled_method

      parser = compiler.parser
      parser.root Rubinius::AST::Script
      parser.input string, file, line

      printer = compiler.packager.print
      printer.bytecode = true
      printer.method_names = []

      compiler.run
    end

    def self.compile_eval(string, scope = nil, file = "(eval)", line = 1)
      compiler = new :atomo_string, :compiled_method

      parser = compiler.parser
      parser.root Rubinius::AST::EvalExpression
      parser.input string, file, line

      printer = compiler.packager.print
      printer.bytecode = true
      printer.method_names = []

      compiler.generator.variable_scope = scope

      compiler.run
    end

    def self.evaluate(string, bnd = nil, file = "(eval)", line = 1)
      if bnd.nil?
        bnd = Binding.setup(
          Rubinius::VariableScope.of_sender,
          Rubinius::CompiledMethod.of_sender,
          Rubinius::StaticScope.of_sender
        )
      end

      cm = compile_eval(string, bnd.variables, file, line)
      cm.scope = bnd.static_scope.dup
      cm.name = :__atomo_eval__

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
      be.call
    end
  end
end