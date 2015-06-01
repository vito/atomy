require "spec_helper"

require "atomy/bootstrap"
require "atomy/code/assign"

describe Atomy::Code::Assign do
  let(:compile_module) { Atomy::Module.new { use Atomy::Bootstrap } }

  let(:eval_binding) { compile_module.compile_context }

  subject { described_class.new(pattern, value) }

  def assign!(binding = eval_binding)
    code = Atomy::Compiler.package(__FILE__.to_sym, __LINE__) do |gen|
      subject.bytecode(gen, compile_module)
    end

    blk = Atomy::Compiler.construct_block(code, binding)

    blk.call
  end

  context "with a wildcard matcher" do
    context "with bindings" do
      let(:pattern) { ast("a") }
      let(:value) { ast("1") }

      it "returns the matched value" do
        a = nil
        expect(assign!(binding)).to eq(1)
      end

      it "assigns them in the given scope" do
        a = nil
        assign!(binding)
        expect(a).to eq(1)
      end
    end

    context "with no bindings" do
      let(:pattern) { ast("_") }
      let(:value) { ast("1") }

      it "returns the matched value" do
        a = nil
        expect(assign!(binding)).to eq(1)
      end

      it "does not affect locals" do
        a = nil
        assign!(binding)
        expect(a).to be nil
      end
    end
  end

  context "when the pattern does not match" do
    let(:pattern) { ast("1") }
    let(:value) { ast("2") }

    it "raises Atomy::PatternMismatch" do
      expect {
        assign!
      }.to raise_error(Atomy::PatternMismatch)
    end
  end
end
