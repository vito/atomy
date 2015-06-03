require "atomy/compiler"
require "atomy/locals"
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
      gen.set_line(node.line) if node.respond_to?(:line) && node.line

      expanded = node
      while expanded.is_a?(Atomy::Grammar::AST::Node)
        expanded = expand(expanded)
      end

      expanded.bytecode(gen, self)
    end

    def evaluate(node, binding = nil)
      binding ||=
        Binding.setup(
          Rubinius::VariableScope.of_sender,
          Rubinius::CompiledCode.of_sender,
          Rubinius::ConstantScope.of_sender,
          self)

      code = Atomy::Compiler.compile(
        node,
        self,
        Atomy::EvalLocalState.new(binding.variables))

      code.add_metadata :for_eval, true

      block = Atomy::Compiler.construct_block(code, binding)
      block.call
    end

    def require(path)
      Atomy::CodeLoader.require(path)
    end

    def use(mod)
      extend mod
      include mod
      mod
    end

    # Node -> (Node | Code)
    def expand(node)
      raise UnknownCode.new(node)
    end

    # Node -> Code::Pattern
    def pattern(node)
      raise UnknownPattern.new(node)
    end

    def compile_context
      return @compile_context if @compile_context

      scope = Rubinius::ConstantScope.new(
        self,
        Rubinius::ConstantScope.new(Object))

      meth = proc {}.block.compiled_code
      meth.metadata = nil
      meth.name = :__script__
      meth.scope = scope

      variables =
        Rubinius::VariableScope.synthesize(
          meth, self, nil, self, nil, Rubinius::Tuple.new(0))

      if @file
        script = meth.create_script
        script.file_path = @file.to_s
        script.data_path = File.expand_path(@file.to_s)
        script.make_main!

        scope.script = script
      end

      @compile_context = Binding.setup(variables, meth, scope)
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
