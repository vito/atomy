require "spec_helper"

require "atomy/bootstrap"
require "atomy/module"
require "atomy/code/define_method"

describe Atomy::Code::DefineMethod do
  let(:name) { :foo }
  let(:body) { ast("0") }
  let(:receiver) { nil }
  let(:arguments) { [] }

  let(:compile_module) do
    Atomy::Module.new do
      use Atomy::Bootstrap
    end
  end

  let(:eval_binding) { compile_module.compile_context }

  subject { described_class.new(name, body, receiver, arguments) }

  def define!
    code = Atomy::Compiler.package(__FILE__.to_sym, __LINE__) do |gen|
      subject.bytecode(gen, compile_module)
    end

    blk = Atomy::Compiler.construct_block(code, eval_binding)

    blk.call
  end

  context "without a receiver" do
    it "defines the method on the ConstantScope's for_method_definition" do
      mod = Atomy::Module.new
      eval_binding.constant_scope.current_module = mod
      define!
      expect(mod.foo).to eq(0)
    end
  end
end
