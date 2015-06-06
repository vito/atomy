require "spec_helper"

require "atomy/module"
require "atomy/pattern/or"
require "atomy/pattern/equality"
require "atomy/pattern/wildcard"

describe Atomy::Pattern::Or do
  let(:a) { wildcard }
  let(:b) { wildcard }

  subject { described_class.new(a, b) }

  def wildcard(name = nil)
    Atomy::Pattern::Wildcard.new(name)
  end

  def equality(value)
    Atomy::Pattern::Equality.new(value)
  end

  describe "#a" do
    it "returns the first pattern" do
      expect(subject.a).to eq(a)
    end
  end

  describe "#b" do
    it "returns the second pattern" do
      expect(subject.b).to eq(b)
    end
  end

  describe "#matches?" do
    context "when 'a' matches" do
      let(:a) { equality(0) }

      context "and 'b' matches" do
        let(:b) { wildcard }

        it { should === 0 }
      end

      context "and 'b' does not match" do
        let(:b) { equality(1) }

        it { should === 0 }

        it "does not even check if b matches" do
          expect(b).to_not receive(:matches?)
          a === 0
        end
      end
    end

    context "when 'a' does not match" do
      context "and 'b' matches" do
        let(:a) { equality(0) }
        let(:b) { wildcard }

        it { should === 1 }
      end

      context "and 'b' does not match" do
        let(:a) { equality(0) }
        let(:b) { equality(0) }

        it { should_not === 1 }
      end
    end
  end

  describe "#assign" do
    context "when 'a' matches and binds" do
      let(:a) { wildcard(:a) }

      context "and 'b' also matches and binds" do
        let(:b) { wildcard(:b) }

        it "assigns only the locals from 'a'" do
          a = nil
          b = nil
          subject.assign(Rubinius::VariableScope.current, 42)
          expect(a).to eq(42)
          expect(b).to be_nil
        end
      end

      context "and 'b' also matches but does NOT bind" do
        it "assigns the 'a' locals" do
          a = nil
          subject.assign(Rubinius::VariableScope.current, 42)
          expect(a).to eq(42)
        end
      end
    end

    context "when 'a' does NOT match" do
      let(:a) { equality(:no_match) }

      context "and 'b' matches and binds" do
        let(:b) { wildcard(:b) }

        it "assigns the 'b' locals" do
          b = nil
          subject.assign(Rubinius::VariableScope.current, 42)
          expect(b).to eq(42)
        end
      end

      context "and 'b' does NOT bind" do
        it "does nothing" do
          subject.assign(Rubinius::VariableScope.current, 42)
        end
      end
    end
  end
end
