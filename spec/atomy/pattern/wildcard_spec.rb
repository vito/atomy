require "spec_helper"

require "atomy/module"
require "atomy/pattern/wildcard"

describe Atomy::Pattern::Wildcard do
  describe "#name" do
    subject { described_class.new(:abc) }
    
    it "returns the binding" do
      expect(subject.name).to eq(:abc)
    end
  end

  describe "#matches?" do
    it_compiles_as(:matches?) do |gen|
      gen.pop
      gen.push_true
    end
  end

  describe "#deconstruct" do
    context "when there are no bindings" do
      it_compiles_as(:deconstruct) {}
    end

    context "when there is a binding" do
      subject { described_class.new(:abc) }

      it_compiles_as(:deconstruct) do |gen|
        gen.set_local(0)
      end
    end
  end

  describe "#wildcard?" do
    it "returns true" do
      expect(subject.wildcard?).to eq(true)
    end
  end

  describe "#inlineable?" do
    it { should be_inlineable }
  end

  describe "#binds?" do
    context "when there are no bindings" do
      it "returns false" do
        expect(subject.binds?).to eq(false)
      end
    end

    context "when there is a binding" do
      subject { described_class.new(:abc) }

      it "returns true" do
        expect(subject.binds?).to eq(true)
      end
    end
  end

  describe "#precludes?" do
    it "returns true" do
      expect(subject.precludes?(double)).to eq(true)
    end
  end
end
