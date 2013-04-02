require "atomy/compiler"
require "atomy/errors"

require "atomy/method"

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

    def expand(node)
      raise UnknownCode.new(node)
    end

    def pattern(node)
      raise UnknownPattern.new(node)
    end

    private

    # atomy module semantics are defined via 'extend self', but we have to
    # make sure that later extends are added *after* self
    #
    # this ensures that modules a module use don't take priority over the
    # module's own methods
    def extend(mod)
      return super if mod == self

      mod.include_into(singleton_class.direct_superclass)
    end
  end
end
