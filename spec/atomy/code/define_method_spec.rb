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

  context "with a receiver" do
    let(:receiver) { ast("42") }

    it "defines on the receiver pattern's target" do
      expect {
        define!
      }.to change { 42.class.instance_methods.include?(:foo) }.to(true)
    end

    it "pattern-matches on the receiver" do
      define!
      expect(42.foo).to eq(0)
      expect { 43.foo }.to raise_error(Atomy::MessageMismatch)
    end
  end

  context "without a receiver" do
    it "defines the method on the LexicalScope's for_method_definition" do
      mod = Atomy::Module.new
      eval_binding.lexical_scope.current_module = mod
      define!
      expect(mod.foo).to eq(0)
    end
  end
end
