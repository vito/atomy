require "spec_helper"

require "atomy/bootstrap"
require "atomy/module"
require "atomy/node/equality"
require "atomy/pattern/equality"
require "atomy/pattern/message"
require "atomy/pattern/wildcard"

describe Atomy::Pattern::Message do
  def wildcard(name = nil)
    Atomy::Pattern::Wildcard.new(name)
  end

  def equality(name = nil)
    Atomy::Pattern::Equality.new(name)
  end

  subject { described_class.new(wildcard) }

  describe "#matches?" do
    context "with no arguments" do
      it { should === [] }
      it { should_not === [1] }
    end

    context "with non-wildcard patterns" do
      subject { described_class.new(wildcard, [equality(1)]) }

      it { should_not === [] }
      it { should     === [1] }
      it { should_not === [2] }
      it { should_not === [1, 2] }
    end

    context "with wildcard arguments" do
      subject { described_class.new(wildcard, [wildcard]) }

      it { should_not === [] }
      it { should     === [1] }
      it { should     === [2] }
      it { should_not === [1, 2] }
    end
  end

  describe "#deconstruct" do
    context "when there are no bindings" do
      it_compiles_as(:deconstruct) {}
    end

    context "when the receiver pattern binds" do
      subject { described_class.new(wildcard(:a)) }

      it_compiles_as(:deconstruct) do |gen|
        gen.push_self
        gen.set_local(0)
        gen.pop
      end
    end

    context "when arguments bind" do
      subject { described_class.new(wildcard, [wildcard(:a)]) }

      it_compiles_as(:deconstruct) do |gen|
        gen.dup
        gen.shift_array
        gen.set_local(0)
        gen.pop
        gen.pop
      end
    end

    context "when the arguments bind twice" do
      subject { described_class.new(wildcard, [wildcard(:a), wildcard(:b)]) }

      it_compiles_as(:deconstruct) do |gen|
        gen.dup
        gen.shift_array
        gen.set_local(0)
        gen.pop
        gen.shift_array
        gen.set_local(1)
        gen.pop
        gen.pop
      end
    end

    context "when the arguments bind one local twice" do
      subject { described_class.new(wildcard, [wildcard(:a), wildcard(:a)]) }

      it_compiles_as(:deconstruct) do |gen|
        gen.dup
        gen.shift_array
        gen.set_local(0)
        gen.pop
        gen.shift_array
        gen.set_local(0)
        gen.pop
        gen.pop
      end
    end
  end

  describe "#precludes?" do
    let(:other) { described_class.new(wildcard) }

    context "when the receiver pattern precludes the other" do
      let(:other) { described_class.new(wildcard) }

      subject { described_class.new(wildcard) }

      context "and the number of arguments differ" do
        let(:other) { described_class.new(wildcard) }

        subject { described_class.new(wildcard, [wildcard]) }

        it "returns false" do
          expect(subject.precludes?(other)).to eq(false)
        end
      end

      context "and the arguments preclude the other arguments" do
        let(:other) { described_class.new(wildcard, [wildcard]) }

        subject { described_class.new(wildcard, [wildcard]) }

        it "returns true" do
          expect(subject.precludes?(other)).to eq(true)
        end
      end
      
      context "and the arguments do NOT preclude the other arguments" do
        let(:other) { described_class.new(wildcard, [wildcard]) }

        subject { described_class.new(wildcard, [equality(0)]) }

        it "returns false" do
          expect(subject.precludes?(other)).to eq(false)
        end
      end
    end

    context "when the receiver pattern does NOT preclude the other" do
      let(:other) { described_class.new(wildcard) }

      subject { described_class.new(equality(0)) }

      it "returns false" do
        expect(subject.precludes?(other)).to eq(false)
      end

      context "and the arguments preclude the other arguments" do
        let(:other) { described_class.new(wildcard, [wildcard]) }

        subject { described_class.new(equality(0), [wildcard]) }

        it "returns false" do
          expect(subject.precludes?(other)).to eq(false)
        end
      end
    end
  end

  describe "#binds?" do
    context "when the receiver pattern binds" do
      subject { described_class.new(wildcard(:a)) }

      it "returns true" do
        expect(subject.binds?).to eq(true)
      end
    end

    context "when any of the argument patterns bind" do
      subject { described_class.new(wildcard, [wildcard(:a)]) }

      it "returns true" do
        expect(subject.binds?).to eq(true)
      end
    end

    context "when neither the receiver nor the arguments bind" do
      it "returns false" do
        expect(subject.binds?).to eq(false)
      end
    end
  end
end
