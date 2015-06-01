require "spec_helper"

require "atomy/module"
require "atomy/pattern/kind_of"

describe Atomy::Pattern::KindOf do
  let(:klass) { Fixnum }

  subject { described_class.new(klass) }

  describe "#klass" do
    it "returns the code describing the being matched" do
      expect(subject.klass).to eq(klass)
    end
  end

  describe "#matches?" do
    it { should === 1 }
    it { should_not === "foo" }
    it { should_not === Fixnum }
  end

  describe "#assign" do
    it "does nothing" do
      subject.assign(Rubinius::VariableScope.current, nil)
    end
  end

  describe "#locals" do
    its(:locals) { should be_empty }
  end

  describe "#target" do
    its(:target) { should eq(klass) }
  end
end
