require "atomy/compiler"

module Atomy
  class Module < ::Module
    # [Symbol] Absolute path to the file the module was loaded from.
    attr_accessor :file

    def initialize
      extend self
      super
    end

    def compile(gen, node)
      gen.set_line(node.line) if node.line
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

    def use(mod)
      extend mod
      include mod
      mod
    end
  end
end
