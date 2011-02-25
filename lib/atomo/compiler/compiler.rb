module Atomo
  def self.add_method(target, name, methods)
    # TODO: arguments
    target.dynamic_method(name) do |g|
      done = g.new_label
      g.local_count = methods.collect do |pats, meth|
        pats[0].local_names + pats[1].collect { |p| p.local_names }.flatten
      end.uniq.size

      g.push_self
      methods.each do |pats, meth|
        recv = pats[0]
        args = pats[1]
        g.total_args = args.size
        g.required_args = args.size
        g.push_state Rubinius::AST::ClosedScope.new(123) # TODO: real line

        skip = g.new_label
        argmis = g.new_label
        argmisnobind = g.new_label

        g.dup
        recv.matches?(g) # TODO: skip kind_of matches
        g.gif skip

        if recv.locals > 0
          g.push_self
          recv.deconstruct(g)
        end

        if args.size > 0
          g.cast_for_multi_block_arg
          args.each do |a|
            g.shift_array
            if a.locals > 0
              g.dup
              a.matches?(g)
              g.gif argmis
              a.deconstruct(g)
            else
              a.matches?(g)
              g.gif argmisnobind
            end
          end
          g.pop
        end

        meth.call(g)
        g.goto done

        argmis.set!
        g.pop
        g.pop
        g.goto skip

        argmisnobind.set!
        g.pop

        skip.set!
      end

      g.push_block
      g.send_super name, 0

      done.set!
      g.ret
    end
  end

  class Compiler < Rubinius::Compiler
    attr_accessor :expander, :pragmas

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

    def self.compile_node(node, scope = nil, file = "(eval)", line = 1)
      compiler = new :atomo_pragmas, :compiled_method

      eval = Rubinius::AST::EvalExpression.new(AST::Tree.new([node]))
      eval.file = file

      printer = compiler.packager.print
      printer.bytecode = true
      printer.method_names = []

      compiler.pragmas.input eval

      compiler.generator.variable_scope = scope

      compiler.run
    end

    def self.evaluate_node(node, instance = nil, bnd = nil, file = "(eval)", line = 1)
      if bnd.nil?
        bnd = Binding.setup(
          Rubinius::VariableScope.of_sender,
          Rubinius::CompiledMethod.of_sender,
          Rubinius::StaticScope.of_sender
        )
      end

      cm = compile_node(node, bnd.variables, file, line)
      cm.scope = bnd.static_scope.dup
      cm.name = :__atomo_eval__

      script = Rubinius::CompiledMethod::Script.new(cm, file, true)
      script.eval_binding = bnd
      # script.eval_source = string

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
