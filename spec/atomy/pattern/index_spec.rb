require "spec_helper"

require "atomy/module"
require "atomy/pattern/index"

describe Atomy::Pattern::Index do
  let(:receiver) { [1, 2, 3] }
  let(:arguments) { [1] }

  subject { described_class.new(receiver, arguments) }

  describe "#arguments" do
    it "returns the arguments" do
      expect(subject.arguments).to eq([1])
    end
  end

  describe "#receiver" do
    it "returns the receiver" do
      expect(subject.receiver).to eq([1, 2, 3])
    end
  end

  describe "#matches?" do
    it { should === nil }
    it { should === Object.new }
  end

  describe "#assign" do
    it "sends #[] to the receiver with the given arguments" do
      subject.assign(Rubinius::VariableScope.current, 42)
      expect(receiver).to eq([1, 42, 3])
    end

    context "with multiple arguments" do
      let(:receiver) { [1, 2, 3, 4, 5] }
      let(:arguments) { [1, 2] }

      it "sends with all of them" do
        subject.assign(Rubinius::VariableScope.current, 42)
        expect(receiver).to eq([1, 42, 4, 5])
      end
    end
  end
end
