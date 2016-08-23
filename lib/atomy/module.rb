require "atomy/compiler"
require "atomy/locals"
require "atomy/errors"

require "atomy/method"

module Atomy
  class Module < ::Module
    # [Symbol] Absolute path to the file the module was loaded from.
    attr_reader :file

    def file=(file)
      @file = file
      Rubinius::Type.set_module_name(self, File.basename(file.to_s).to_sym, Object)
    end

    # [Module] Modules users of this module should automatically use.
    attr_reader :exported_modules

    def initialize
      extend self

      @exported_modules = []

      # easy accessor for the current module via LexicalScope lookup
      const_set(:Self, self)

      super
    end

    def export(*modules)
      @exported_modules.concat(modules)
    end

    def compile(gen, node)
      gen.set_line(node.line) if node.respond_to?(:line) && node.line

      expanded = node
      while expanded.is_a?(Atomy::Grammar::AST::Node)
        expanded = expand(expanded)
      end

      expanded.bytecode(gen, self)
    rescue
      puts "when compiling: #{node}"
      raise
    end

    def evaluate(node, binding = nil)
      binding ||=
        Binding.setup(
          Rubinius::VariableScope.of_sender,
          Rubinius::CompiledCode.of_sender,
          Rubinius::LexicalScope.of_sender,
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

    def load(path)
      Atomy::CodeLoader.load(path)
    end

    def inspect
      if @file
        super.sub(/>$/, " #{@file}>")
      else
        super
      end
    end

    def use(mod)
      extend mod
      include mod

      if mod.is_a?(self.class)
        mod.exported_modules.each do |m|
          use(m)
        end
      end

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

      scope = Rubinius::LexicalScope.new(
        self,
        Rubinius::LexicalScope.new(Object))

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
