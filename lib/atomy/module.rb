require "atomy/compiler"

module Atomy
  class Module < ::Module
    def initialize(&blk)
      module_eval(&blk) if blk
    end

    def compile(gen, node)
      expand(node).bytecode(gen, self)
    end

    def evaluate(node)
      binding =
        Binding.setup(
          Rubinius::VariableScope.of_sender,
          Rubinius::CompiledCode.of_sender,
          Rubinius::ConstantScope.of_sender,
          self)

      code = Atomy::Compiler.compile(node, self)
      block = Atomy::Compiler.construct_block(code, binding)

      block.call
    end
  end
end
