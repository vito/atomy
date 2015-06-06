require "spec_helper"

require "atomy/module"
require "atomy/pattern/attribute"

describe Atomy::Pattern::Attribute do
  let(:klass) { Class.new { attr_accessor :abc } }
  let(:receiver) { klass.new }

  subject { described_class.new(:abc, receiver) }

  describe "#attribute" do
    it "returns the attribute" do
      expect(subject.attribute).to eq(:abc)
    end
  end

  describe "#receiver" do
    it "returns the receiver" do
      expect(subject.receiver).to eq(receiver)
    end
  end

  describe "#matches?" do
    it { should === nil }
    it { should === Object.new }
  end

  describe "#assign" do
    it "assigns the attribute on the receiver" do
      subject.assign(Rubinius::VariableScope.current, 42)
      expect(receiver.abc).to eq(42)
    end
  end
end
