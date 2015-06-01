require "spec_helper"

require "atomy/bootstrap"
require "atomy/code/assign"

describe Atomy::Code::Assign do
  let(:compile_module) { Atomy::Module.new { use Atomy::Bootstrap } }

  subject { described_class.new(name, value) }

  let(:name) { :a }
  let(:value) { ast("1") }

  it "returns the matched value" do
    a = nil
    expect(compile_module.evaluate(subject)).to eq(1)
  end

  it "assigns the variable in the current scope" do
    a = :unmodified

    expect(compile_module.evaluate(Atomy::Code::Sequence.new([
      subject,
      Atomy::Code::Variable.new(name),
    ]))).to eq(1)

    expect(a).to eq(:unmodified)
  end
end
