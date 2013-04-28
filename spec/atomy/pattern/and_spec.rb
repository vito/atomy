require "spec_helper"

require "atomy/module"
require "atomy/pattern/and"

describe Atomy::Pattern::And do
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

  describe "#deconstruct" do
    context "when 'a' binds" do
      let(:a) { wildcard(:a) }

      context "and 'b' binds" do
        let(:b) { wildcard(:b) }

        it_compiles_as(:deconstruct) do |gen|
          gen.state.scope.new_local(:a).reference.set_bytecode(gen)
          gen.state.scope.new_local(:b).reference.set_bytecode(gen)
        end
      end

      context "and 'b' does NOT bind" do
        it_compiles_as(:deconstruct) do |gen|
          gen.state.scope.new_local(:a).reference.set_bytecode(gen)
        end
      end
    end

    context "when 'a' does NOT bind" do
      context "and 'b' binds" do
        let(:b) { wildcard(:b) }

        it_compiles_as(:deconstruct) do |gen|
          gen.state.scope.new_local(:b).reference.set_bytecode(gen)
        end
      end

      context "and 'b' does NOT bind" do
        it_compiles_as(:deconstruct) {}
      end
    end
  end

  describe "#wildcard?" do
    context "when 'a' is a wildcard" do
      context "and 'b' is a wildcard" do
        it { should be_wildcard }
      end

      context "and 'b' is NOT a wildcard" do
        let(:b) { equality(0) }

        it { should_not be_wildcard }
      end
    end

    context "when 'a' is NOT a wildcard" do
      let(:a) { equality(0) }

      it { should_not be_wildcard }
    end
  end

  describe "#inlineable?" do
    let(:uninlineable) { Atomy::Pattern.new }

    context "when 'a' is inlineable" do
      context "and 'b' is inlineable" do
        it { should be_inlineable }
      end

      context "and 'b' is NOT inlineable" do
        let(:b) { uninlineable }

        it { should_not be_inlineable }
      end
    end

    context "when 'a' is NOT inlineable" do
      let(:a) { uninlineable }

      it { should_not be_inlineable }
    end
  end

  describe "#binds?" do
    context "when 'a' binds" do
      let(:a) { wildcard(:a) }

      context "and 'b' binds" do
        let(:b) { wildcard(:b) }

        it { should be_binds }
      end

      context "and 'b' does NOT bind" do
        let(:b) { wildcard }

        it { should be_binds }
      end
    end

    context "when 'a' does NOT bind" do
      context "and 'b' binds" do
        let(:b) { wildcard(:b) }

        it { should be_binds }
      end

      context "and 'b' does NOT bind" do
        let(:b) { wildcard }

        it { should_not be_binds }
      end
    end
  end

  describe "#precludes?" do
    let(:other) { equality(0) }

    context "when 'a' precludes" do
      let(:a) { wildcard }

      context "and 'b' precludes" do
        let(:b) { wildcard }

        it "returns true" do
          expect(subject.precludes?(other)).to eq(true)
        end
      end

      context "and 'b' does NOT preclude" do
        let(:b) { equality(1) }

        it "returns false" do
          expect(subject.precludes?(other)).to eq(false)
        end
      end
    end

    context "when 'a' does NOT preclude" do
      let(:a) { equality(1) }

      context "and 'b' precludes" do
        let(:b) { wildcard }

        it "returns false" do
          expect(subject.precludes?(other)).to eq(false)
        end
      end

      context "and 'b' does NOT preclude" do
        let(:b) { equality(2) }

        it "returns false" do
          expect(subject.precludes?(other)).to eq(false)
        end
      end
    end
  end
end
