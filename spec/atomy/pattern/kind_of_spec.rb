require "spec_helper"

require "atomy/module"
require "atomy/pattern/kind_of"

describe Atomy::Pattern::KindOf do
  let(:constant) { Atomy::Code::Constant.new(:Fixnum) }

  subject { described_class.new(constant) }

  describe "#code" do
    it "returns the code describing the being matched" do
      expect(subject.code).to eq(constant)
    end
  end

  describe "#matches?" do
    it_compiles_as(:matches?) do |gen|
      gen.push_const(:Fixnum)
      gen.swap
      gen.kind_of
    end
  end

  describe "#deconstruct" do
    it_compiles_as(:deconstruct) {}
  end

  describe "#wildcard?" do
    it "returns false" do
      expect(subject.wildcard?).to be_false
    end
  end

  describe "#always_matches_self?" do
    it { should be_always_matches_self }
  end

  describe "#inlineable?" do
    it { should_not be_inlineable }
  end

  describe "#binds?" do
    it "returns false" do
      expect(subject.binds?).to be_false
    end
  end

  describe "#target" do
    it_compiles_as(:target) do |gen|
      gen.push_const(:Fixnum)
    end
  end

  describe "#precludes?" do
    context "when the other pattern is a Wildcard" do
      let(:other) { Atomy::Pattern::Wildcard.new }

      it "returns false" do
        expect(subject.precludes?(other)).to eq(false)
      end
    end

    context "when the other pattern is NOT a Wildcard" do
      let(:other) { Atomy::Pattern::Equality.new(1.0) }

      it "returns true" do
        expect(subject.precludes?(other)).to eq(true)
      end
    end

    # TODO: ideally the following would be the semantics
    #context "when the other pattern is a KindOf" do
      #context "and the classes are equal" do
        #let(:other) { described_class.new(Object) }

        #it "returns true" do
          #expect(subject.precludes?(other)).to eq(true)
        #end
      #end

      #context "and my class is a superclass of the other's" do
        #let(:other) { described_class.new(Fixnum) }

        #it "returns true" do
          #expect(subject.precludes?(other)).to eq(true)
        #end
      #end

      #context "and the other class is not equal and not a subclass" do
        #let(:other) { described_class.new(Fixnum) }

        #subject { described_class.new(String) }

        #it "returns false" do
          #expect(subject.precludes?(other)).to be_false
        #end
      #end
    #end

    #context "when the other pattern is an Equality" do
      #let(:other) { Atomy::Pattern::Equality.new(0) }

      #context "and its value is of my class" do
        #subject { described_class.new(Fixnum) }

        #it "returns true" do
          #expect(subject.precludes?(other)).to eq(true)
        #end
      #end

      #context "and its value is NOT of my class" do
        #subject { described_class.new(String) }

        #it "returns true" do
          #expect(subject.precludes?(other)).to be_false
        #end
      #end
    #end

    #context "when the other pattern is not a KindOf or Equality" do
      #it "returns false" do
        #expect(subject.precludes?(Object.new)).to be_false
      #end
    #end
  end
end
