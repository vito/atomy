require "spec_helper"

require "atomy/bootstrap"
require "atomy/code/assign"

describe Atomy::Code::Assign do
  let(:compile_module) { Atomy::Module.new { use Atomy::Bootstrap } }

  let(:pattern) { ast("a") }
  let(:value) { ast("1") }

  subject { described_class.new(pattern, value) }

  it "returns the matched value" do
    a = nil
    expect(compile_module.evaluate(subject)).to eq(1)
  end

  it "pattern-matches the value, assigning locals in the current scope" do
    a = :unmodified

    expect(compile_module.evaluate(Atomy::Code::Sequence.new([
      subject,
      Atomy::Code::Variable.new(:a),
    ]))).to eq(1)

    expect(a).to eq(:unmodified)
  end

  context "when the pattern does not match" do
    let(:pattern) { ast("2") }

    it "raises Atomy::PatternMismatch" do
      expect {
        compile_module.evaluate(subject)
      }.to raise_error(Atomy::PatternMismatch)
    end
  end
end
