module Atomy
  module Compiler
    module_function

    def compile(node, mod, file = nil, line = 0)
      gen = Rubinius::Generator.new
      gen.file = file && file.to_sym
      gen.set_line(line)

      mod.compile(gen, node)
      gen.ret

      gen.close
      gen.encode

      gen.package(Rubinius::CompiledCode)
    end

    def construct_block(code, binding)
      code = code.dup

      code.add_metadata(:for_eval, true)

      code.scope = binding.constant_scope
      code.name = binding.variables.method.name

      code.scope.script =
        Rubinius::CompiledCode::Script.new(code, code.file.to_s, true)

      block = Rubinius::BlockEnvironment.new
      block.under_context(binding.variables, code)
      block.proc_environment = binding.proc_environment
      block.from_eval!

      block
    end
  end
end
