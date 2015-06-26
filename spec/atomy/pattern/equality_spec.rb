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

  describe "#inline_matches?" do
    subject { described_class.new(value) }

    context "with true" do
      let(:value) { true }

      it_compiles_as(:inline_matches?) do |gen|
        gen.push_true
        gen.swap
        gen.send(:==, 1)
      end
    end

    context "with false" do
      let(:value) { false }

      it_compiles_as(:inline_matches?) do |gen|
        gen.push_false
        gen.swap
        gen.send(:==, 1)
      end
    end

    context "with nil" do
      let(:value) { nil }

      it_compiles_as(:inline_matches?) do |gen|
        gen.push_nil
        gen.swap
        gen.send(:==, 1)
      end
    end

    context "with Integers" do
      let(:value) { 42 }

      it_compiles_as(:inline_matches?) do |gen|
        gen.push_int(42)
        gen.swap
        gen.send(:==, 1)
      end
    end

    context "with other values" do
      let(:value) { Object.new }

      it_compiles_as(:inline_matches?) do |gen|
        gen.push_literal(value)
        gen.swap
        gen.send(:==, 1)
      end
    end
  end
end
