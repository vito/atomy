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

      it_compiles_as(:matches?) do |gen|
        gen.push_int(42)
        gen.send(:==, 1)
      end
    end

    context "with 'true'" do
      subject { described_class.new(true) }

      it_compiles_as(:matches?) do |gen|
        gen.push_true
        gen.send(:==, 1)
      end
    end

    context "with 'false'" do
      subject { described_class.new(false) }

      it_compiles_as(:matches?) do |gen|
        gen.push_false
        gen.send(:==, 1)
      end
    end

    context "with 'nil'" do
      subject { described_class.new(nil) }

      it_compiles_as(:matches?) do |gen|
        gen.push_nil
        gen.send(:==, 1)
      end
    end

    context "with a string" do
      subject { described_class.new("foobar") }

      it_compiles_as(:matches?) do |gen|
        gen.push_literal("foobar")
        gen.string_dup
        gen.send(:==, 1)
      end
    end

    context "with anything else" do
      subject { described_class.new(Object.new) }

      # TODO: better error
      it "raises an error" do
        expect {
          subject.matches?(nil, nil)
        }.to raise_error
      end
    end
  end

  describe "#deconstruct" do
    it_compiles_as(:deconstruct) {}
  end

  describe "#wildcard?" do
    it "returns false" do
      expect(subject.wildcard?).to eq(false)
    end
  end

  describe "#binds?" do
    it "returns false" do
      expect(subject.binds?).to eq(false)
    end
  end
end
