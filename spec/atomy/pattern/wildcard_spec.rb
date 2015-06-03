require "spec_helper"

require "atomy/module"
require "atomy/pattern/wildcard"

describe Atomy::Pattern::Wildcard do
  describe "#name" do
    context "when no name is given" do
      subject { described_class.new }

      it "returns nil" do
        expect(subject.name).to be_nil
      end
    end

    context "when a name is given" do
      subject { described_class.new(:abc) }

      it "returns the name" do
        expect(subject.name).to eq(:abc)
      end
    end
  end

  describe "#matches?" do
    it { should === nil }
    it { should === Object.new }
  end

  describe "#bindings" do
    context "when no name is given" do
      subject { described_class.new }

      it "returns no bindings" do
        expect(subject.bindings(42)).to be_empty
      end
    end

    context "when a name is given" do
      subject { described_class.new(:abc) }

      it "returns the bound value" do
        expect(subject.bindings(42)).to eq([42])
      end
    end
  end
end
