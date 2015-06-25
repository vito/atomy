require "spec_helper"

require "atomy/module"
require "atomy/pattern/attribute"

describe Atomy::Pattern::Attribute do
  let(:klass) { Class.new { attr_accessor :abc } }
  let(:receiver) { klass.new }
  let(:arguments) { [Object.new, Object.new] }

  subject { described_class.new(receiver, arguments) }

  describe "#receiver" do
    it "returns the receiver" do
      expect(subject.receiver).to eq(receiver)
    end
  end

  describe "#arguments" do
    it "returns the arguments" do
      expect(subject.arguments).to eq(arguments)
    end
  end

  describe "#matches?" do
    it { should === nil }
    it { should === Object.new }
  end
end
