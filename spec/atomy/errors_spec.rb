require "spec_helper"

require "atomy/errors"

describe Atomy::UnknownPattern do
  let(:node) { ast("foo") }

  subject { described_class.new(node) }

  describe "#node" do
    it "returns the node that was unknown" do
      expect(subject.node).to eq(node)
    end
  end

  describe "#to_s" do
    it "mentions the node" do
      expect(subject.to_s).to include(node.to_s)
    end
  end
end

describe Atomy::UnknownCode do
  let(:node) { ast("foo") }

  subject { described_class.new(node) }

  describe "#node" do
    it "returns the node that was unknown" do
      expect(subject.node).to eq(node)
    end
  end

  describe "#to_s" do
    it "mentions the node" do
      expect(subject.to_s).to include(node.to_s)
    end
  end
end

describe Atomy::PatternMismatch do
  let(:pattern) { Atomy::Pattern::Wildcard.new }
  let(:value) { 123 }

  subject { described_class.new(pattern, value) }

  describe "#pattern" do
    it "returns the node that mismatched" do
      expect(subject.pattern).to eq(pattern)
    end
  end

  describe "#value" do
    it "returns the value that mismatched" do
      expect(subject.value).to eq(value)
    end
  end

  describe "#to_s" do
    it "says the pattern did not match" do
      expect(subject.to_s).to include("did not match")
    end
  end
end

describe Atomy::MessageMismatch do
  let(:receiver) { Object.new }
  let(:arguments) { [Object.new] }
  let(:name) { :foo }

  subject { described_class.new(name, receiver, arguments) }

  describe "#receiver" do
    it "returns the receiver of the message" do
      expect(subject.receiver).to eq(receiver)
    end
  end

  describe "#arguments" do
    it "returns the arguments of the message" do
      expect(subject.arguments).to eq(arguments)
    end
  end

  describe "#name" do
    it "returns the name of the message" do
      expect(subject.name).to eq(name)
    end
  end

  describe "#to_s" do
    it "says the pattern did not match" do
      expect(subject.to_s).to include("was not understood by")
    end
  end
end
