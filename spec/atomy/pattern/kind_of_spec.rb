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

  describe "#precludes?" do
    context "when the other pattern is a Wildcard" do
      let(:other) { Atomy::Pattern::Wildcard.new }

      it "returns false" do
        expect(subject.precludes?(other)).to eq(false)
      end
    end

    context "when the other pattern is a KindOf" do
      context "and the classes are equal" do
        let(:other) { described_class.new(klass) }

        it "returns true" do
          expect(subject.precludes?(other)).to eq(true)
        end
      end

      context "and my class is a superclass of the other's" do
        let(:other) { described_class.new(Fixnum) }

        it "returns true" do
          expect(subject.precludes?(other)).to eq(true)
        end
      end

      context "and the other class is not equal and not a subclass" do
        let(:other) { described_class.new(Fixnum) }

        subject { described_class.new(String) }

        it "returns false" do
          expect(subject.precludes?(other)).to eq(false)
        end
      end
    end

    context "when the other pattern is not a KindOf or a Wildcard" do
      it "returns true" do
        expect(subject.precludes?(Object.new)).to eq(true)
      end
    end
  end
end
