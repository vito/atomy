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

    def self.compile(mod, output = nil, debug = false)
      compiler = new :atomy_file, :compiled_file

      compiler.parser.root Atomy::AST::Script
      compiler.parser.input mod

      compiler.generator.module mod

      compiler.packager.print.bytecode = debug if debug

      compiler.writer.name = output ? output : compiled_name(mod.file.to_s)

      compiler.run
    end

    def self.compile_eval_string(string, mod, scope = nil,
                                 file = "(eval)", line = 1, debug = false)
      compiler = new :atomy_string, :compiled_method

      compiler.parser.root Atomy::AST::EvalExpression
      compiler.parser.input string, mod, file, line

      compiler.packager.print.bytecode = debug if debug

      compiler.generator.module mod
      compiler.generator.variable_scope = scope

      cm = compiler.run
      cm.add_metadata :for_eval, true
      cm
    end

    def self.compile_eval_node(node, mod, scope = nil,
                               file = "(eval)", line = 1, debug = false)
      compiler = new :atomy_bytecode, :compiled_method

      expr = Atomy::AST::EvalExpression.new(AST::Tree.new(:line => line, :nodes => [node]))
      expr.file = file

      compiler.packager.print.bytecode = debug if debug

      compiler.generator.module mod
      compiler.generator.input expr
      compiler.generator.variable_scope = scope

      cm = compiler.run
      cm.add_metadata :for_eval, true
      cm
    end

    def self.construct_block(string_or_node, mod, binding, file="(eval)", line=1, debug = false)
      if string_or_node.is_a?(String)
        cm = compile_eval_string string_or_node, mod, binding.variables, file, line, debug
      else
        cm = compile_eval_node string_or_node, mod, binding.variables, file, line, debug
      end

      cm.scope = binding.constant_scope
      cm.name = binding.variables.method.name

      unless cm.scope.script
        # This has to be setup so __FILE__ works in eval.
        script = Rubinius::CompiledMethod::Script.new(cm, file, true)
        if string_or_node.is_a?(String)
          script.eval_source = string_or_node
        end

        cm.scope.script = script
      end

      be = Rubinius::BlockEnvironment.new
      be.under_context binding.variables, cm

      # Pass the BlockEnvironment this binding was created from
      # down into the new BlockEnvironment we just created.
      # This indicates the "declaration trace" to the stack trace
      # mechanisms, which can be different from the "call trace"
      # in the case of, say: eval("caller", a_proc_instance)
      if binding.from_proc?
        be.proc_environment = binding.proc_environment
      end

      be.from_eval!

      return be
    end

    def self.eval(
        string_or_node, mod, binding = nil,
        filename = mod.file, line = 1, debug = false)
      filename = filename.to_s if filename
      lineno = lineno.to_i

      if binding
        if binding.kind_of? Proc
          binding = binding.binding
        elsif binding.respond_to? :to_binding
          binding = binding.to_binding
        end

        unless binding.kind_of? Binding
          raise ArgumentError, "unknown type of binding"
        end

        filename ||= binding.constant_scope.active_path
      else
        binding = Binding.setup(Rubinius::VariableScope.of_sender,
                                Rubinius::CompiledMethod.of_sender,
                                Rubinius::ConstantScope.of_sender,
                                self)

        filename ||= "(eval)"
      end

      binding.constant_scope = binding.constant_scope.dup

      be = Atomy::Compiler.construct_block string_or_node, mod, binding,
                                           filename, lineno, debug

      be.set_eval_binding binding

      be.call_on_instance(binding.self)
    end
  end
end
