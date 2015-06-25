require "spec_helper"

require "atomy/module"
require "atomy/pattern/and"
require "atomy/pattern/equality"
require "atomy/pattern/wildcard"

describe Atomy::Pattern::And do
  let(:a) { wildcard }
  let(:b) { wildcard }

  subject { described_class.new(a, b) }

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

        it { should_not === 0 }
      end
    end

    context "when 'a' does not match" do
      context "and 'b' matches" do
        let(:a) { equality(0) }
        let(:b) { wildcard }

        it { should_not === 1 }
      end

      context "and 'b' does not match" do
        let(:a) { equality(0) }
        let(:b) { equality(0) }

        it { should_not === 1 }
      end
    end
  end

  describe "#target" do
    let(:parent) { Class.new }
    let(:child) { Class.new(parent) }

    context "when the lhs is more specific" do
      let(:a) { double(target: parent) }
      let(:b) { double(target: child) }

      its(:target) { should == child }
    end

    context "when the rhs is more specific" do
      let(:a) { double(target: child) }
      let(:b) { double(target: parent) }

      its(:target) { should == child }
    end
  end
end
