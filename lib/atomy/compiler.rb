require "atomy/locals"

module Atomy
  module Compiler
    module_function

    def compile(node, mod)
      package(mod.file) do |gen|
        mod.compile(gen, node)
      end
    end

    def package(file, line = 0, &blk)
      generate(file, line, &blk).package(Rubinius::CompiledCode)
    end

    def generate(file, line = 0)
      gen = Rubinius::Generator.new
      gen.file = file
      gen.set_line(0)

      gen.push_state(LocalState.new)

      yield gen

      gen.ret

      gen.close

      gen.local_count = gen.state.scope.local_count
      gen.local_names = gen.state.scope.local_names

      gen.encode

      gen
    end

    def construct_block(code, binding)
      code = code.dup
      code.scope = binding.constant_scope
      code.name = binding.variables.method.name
      code.scope.script =
        Rubinius::CompiledCode::Script.new(code, code.file.to_s, true)

      block = Rubinius::BlockEnvironment.new
      block.under_context(binding.variables, code)
      block
    end
  end
end
