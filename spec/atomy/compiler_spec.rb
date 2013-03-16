require "spec_helper"

require "atomy/compiler"
require "atomy/module"


describe Atomy::Compiler do
  class SomeCode
    def bytecode(gen, mod)
      gen.push_int 42
    end
  end

  let(:node) { ast("42") }

  let(:compile_module) do
    Atomy::Module.new do
      def expand(_)
        SomeCode.new
      end
    end
  end

  describe ".compile" do
    it "returns a CompiledCode" do
      expect(described_class.compile(node, compile_module)).to(
        be_a(Rubinius::CompiledCode))
    end
    
    it "has the given file on the CompiledCode" do
      code = described_class.compile(node, compile_module, "some/file")
      expect(code.file).to eq(:"some/file")
    end
    
    it "has the given line on the CompiledCode" do
      code = described_class.compile(node, compile_module, nil, 3)
      expect(code.first_line).to eq(3)
    end
  end

  describe ".construct_block" do
    let(:code) do
      described_class.compile(node, compile_module)
    end

    it "creates a BlockEnvironment from CompiledCode" do
      expect(described_class.construct_block(code, binding)).to(
        be_a(Rubinius::BlockEnvironment))
    end

    it "does not mutate the CompiledCode" do
      expect {
        described_class.construct_block(code, binding)
      }.to_not change { code.dup }
    end

    it "has the binding's variable scope for the block" do
      block = described_class.construct_block(code, binding)
      expect(block.scope).to eq(binding.variables)
    end

    it "sets the block's proc_environment to the binding's" do
      bnd = binding.dup
      bnd.proc_environment = mock
      block = described_class.construct_block(code, bnd)
      expect(block.proc_environment).to eq(bnd.proc_environment)
    end

    it "sets for_eval on the block's CompiledCode" do
      block = described_class.construct_block(code, binding)
      expect(block.compiled_code.for_eval?).to be_true
    end

    it "sets from_eval? on the block" do
      block = described_class.construct_block(code, binding)
      expect(block.from_eval?).to be_true
    end

    it "sets the code's scope to the binding's constant scope" do
      block = described_class.construct_block(code, binding)
      expect(block.compiled_code.scope).to eq(binding.constant_scope)
    end

    it "sets the code's name to the binding's variable scope method name" do
      block = described_class.construct_block(code, binding)
      expect(block.compiled_code.name).to eq(binding.variables.method.name)
    end

    describe "determining the path" do
      class FileCode
        def bytecode(gen, mod)
          gen.push_scope
          gen.send :active_path, 0
        end
      end

      let(:compile_module) do
        Atomy::Module.new do
          def expand(_)
            FileCode.new
          end
        end
      end

      it "reflects the file path of the code" do
        code.file = :"foo/bar.rb"
        block = described_class.construct_block(code, binding)
        expect(block.call).to eq("foo/bar.rb")
      end
    end

    # TODO: I want to spec this using locals access or something.
    it "constructs the block with the given binding"
  end
end
