require "spec_helper"

require "atomy/module"
require "atomy/pattern/or"
require "atomy/pattern/equality"
require "atomy/pattern/wildcard"

describe Atomy::Pattern::Or do
  let(:a) { wildcard }
  let(:b) { wildcard }

  subject { described_class.new(a, b) }

  def wildcard
    Atomy::Pattern::Wildcard.new
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

  describe "#inline_matches?" do
    let(:a) { equality(0) }
    let(:b) { wildcard }

    it_compiles_as(:inline_matches?) do |gen|
      match = gen.new_label
      done = gen.new_label

      gen.dup

      gen.push_int(0)
      gen.swap
      gen.send(:==, 1)
      gen.goto_if_true(match)

      gen.pop
      gen.push_true
      gen.goto(done)

      match.set!

      gen.pop
      gen.push_true

      done.set!
    end
  end
end
