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

  describe "#assign" do
    context "when 'a' binds" do
      let(:a) { wildcard(:a) }

      context "and 'b' binds" do
        let(:b) { wildcard(:b) }

        it "assigns all locals" do
          a = nil
          b = nil
          subject.assign(Rubinius::VariableScope.current, 42)
          expect(a).to eq(42)
          expect(b).to eq(42)
        end
      end

      context "and 'b' does NOT bind" do
        it "assigns the 'a' locals" do
          a = nil
          subject.assign(Rubinius::VariableScope.current, 42)
          expect(a).to eq(42)
        end
      end
    end

    context "when 'a' does NOT bind" do
      context "and 'b' binds" do
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
