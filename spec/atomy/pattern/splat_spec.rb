require "spec_helper"

require "atomy/module"
require "atomy/node/equality"
require "atomy/pattern/equality"
require "atomy/pattern/splat"
require "atomy/pattern/wildcard"

describe Atomy::Pattern::Splat do
  subject { described_class.new(Atomy::Pattern.new) }

  describe "#pattern" do
    let(:pattern) { Atomy::Pattern.new }

    subject { described_class.new(pattern) }

    it "returns the pattern" do
      expect(subject.pattern).to eq(pattern)
    end
  end

  describe "#matches?" do
    class SomePattern
      def matches?(gen)
        gen.push_literal(:some_pattern)
        gen.send(:==, 1)
      end
    end

    subject { described_class.new(SomePattern.new) }

    it_compiles_as(:matches?) do |gen|
      gen.push_literal(:some_pattern)
      gen.send(:==, 1)
    end
  end

  describe "#locals" do
    context "when its pattern binds" do
      subject { described_class.new(Atomy::Pattern::Wildcard.new(:abc)) }

      it "returns its locals" do
        expect(subject.locals).to eq([:abc])
      end
    end

    context "when its pattern does NOT bind" do
      subject { described_class.new(Atomy::Pattern::Wildcard.new) }

      it "returns an empty array" do
        expect(subject.locals).to be_empty
      end
    end
  end

  describe "#assign" do
    context "when its pattern binds" do
      subject { described_class.new(Atomy::Pattern::Wildcard.new(:abc)) }

      it "assigns them in the given scope" do
        abc = nil
        subject.assign(Rubinius::VariableScope.current, [ast("foo"), ast("bar")])
        expect(abc).to eq([ast("foo"), ast("bar")])
      end
    end

    context "when its pattern does NOT bind" do
      subject { described_class.new(Atomy::Pattern::Wildcard.new) }

      it "does not assign anything" do
        abc = nil
        subject.assign(Rubinius::VariableScope.current, [ast("foo"), ast("bar")])
        expect(abc).to be_nil
      end
    end
  end

  describe "#precludes?" do
    context "when the other pattern is a Splat" do
      let(:other) { described_class.new(Atomy::Pattern::Equality.new(1)) }

      context "and I preclude its pattern" do
        subject { described_class.new(Atomy::Pattern::Wildcard.new) }

        it "returns true" do
          expect(subject.precludes?(other)).to eq(true)
        end
      end

      context "and I do NOT preclude its pattern" do
        subject { described_class.new(Atomy::Pattern::Equality.new(0)) }

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

