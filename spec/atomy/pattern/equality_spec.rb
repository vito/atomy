require "spec_helper"

require "atomy/module"
require "atomy/pattern/equality"

describe Atomy::Pattern::Equality do
  subject { described_class.new(nil) }

  describe "#value" do
    subject { described_class.new(42) }

    it "returns the value being matched" do
      expect(subject.value).to eq(42)
    end
  end

  describe "#matches?" do
    context "with an integer" do
      subject { described_class.new(42) }

      it { should === 42 }
      it { should_not === 24 }
    end

    context "with 'true'" do
      subject { described_class.new(true) }

      it { should === true }
      it { should_not === false }
    end

    context "with 'false'" do
      subject { described_class.new(false) }

      it { should === false }
      it { should_not === true }
    end

    context "with 'nil'" do
      subject { described_class.new(nil) }

      it { should === nil }
      it { should_not === 42 }
    end

    context "with a string" do
      subject { described_class.new("foobar") }

      it { should === "foobar" }
      it { should_not === "fizzbuzz" }
    end

    context "with a node" do
      subject { described_class.new(ast("1 + a")) }

      it { should === ast("1 + a") }
      it { should_not === ast("1 + b") }
    end
  end

  describe "#locals" do
    its(:locals) { should be_empty }
  end

  describe "#assign" do
    it "does nothing" do
      subject.assign(Rubinius::VariableScope.current, 42)
    end
  end

  describe "#target" do
    context "with a fixnum" do
      subject { described_class.new(42) }

      its(:target) { should eq(Fixnum) }
    end

    context "with 'true'" do
      subject { described_class.new(true) }

      its(:target) { should eq(TrueClass) }
    end

    context "with 'false'" do
      subject { described_class.new(false) }

      its(:target) { should eq(FalseClass) }
    end

    context "with 'nil'" do
      subject { described_class.new(nil) }

      its(:target) { should eq(NilClass) }
    end

    context "with a string" do
      subject { described_class.new("foobar") }

      its(:target) { should eq(String) }
    end

    context "with a node" do
      subject { described_class.new(ast("1 + a")) }

      its(:target) { should eq(Atomy::Grammar::AST::Infix) }
    end
  end

  describe "#precludes?" do
    context "when the other pattern is an Equality" do
      let(:other) { described_class.new(1) }

      context "and the values are equal" do
        subject { described_class.new(1) }

        it "returns true" do
          expect(subject.precludes?(other)).to eq(true)
        end
      end

      context "and the values are NOT equal" do
        subject { described_class.new(0) }

        it "returns false" do
          expect(subject.precludes?(other)).to eq(false)
        end
      end
    end

    context "when the other pattern is not an Equality" do
      it "returns false" do
        expect(subject.precludes?(Object.new)).to eq(false)
      end
    end
  end
end
