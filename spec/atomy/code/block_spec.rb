require "spec_helper"

require "atomy/bootstrap"
require "atomy/code/block"

describe Atomy::Code::Block do
  let(:compile_module) { Atomy::Module.new { use Atomy::Bootstrap } }

  let(:body) { ast("a + b") }
  let(:args) { [ast("a"), ast("b")] }

  subject { described_class.new(body, args) }

  it "constructs a Proc with the correct arity" do
    blk = compile_module.evaluate(subject)
    expect(blk).to be_kind_of(Proc)
    expect(blk.arity).to eq(2)
  end

  context "when called with the correct argument count" do
    it "binds arguments as locals and executes the body" do
      expect(compile_module.evaluate(subject).call(1, 2)).to eq(3)
    end
  end

  context "when any argument patterns do not match" do
    let(:args) { [ast("1"), ast("b")] }
    let(:body) { ast("b + 3") }

    it "raises Atomy::PatternMismatch" do
      expect(compile_module.evaluate(subject).call(1, 2)).to eq(5)

      expect {
        compile_module.evaluate(subject).call(2, 2)
      }.to raise_error(Atomy::PatternMismatch)
    end
  end

  context "when called with too many arguments" do
    it "raises ArgumentError" do
      expect {
        compile_module.evaluate(subject).call(1, 2, 3)
      }.to raise_error(ArgumentError)
    end
  end

  context "when called with too few arguments" do
    it "raises ArgumentError" do
      expect {
        compile_module.evaluate(subject).call(1)
      }.to raise_error(ArgumentError)
    end
  end
end
