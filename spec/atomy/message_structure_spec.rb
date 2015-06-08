require "spec_helper"

require "atomy/message_structure"
require "atomy/node/equality"

describe Atomy::MessageStructure do
  subject { described_class.new(node) }

  context "when not a message-like structure" do
    let(:node) { ast("42") }

    describe "#name" do
      it "raises UnknownMessageStructure" do
        expect { subject.name }.to raise_error(described_class::UnknownMessageStructure)
      end
    end

    its(:arguments) { should be_empty }
    its(:receiver) { should be_nil }
    its(:proc_argument) { should be_nil }
  end

  context "when a word" do
    let(:node) { ast("foo") }
    its(:name) { should == :foo }
    its(:arguments) { should be_empty }
    its(:receiver) { should be_nil }
    its(:proc_argument) { should be_nil }
  end

  context "when a word followed by !" do
    let(:node) { ast("foo!") }
    its(:name) { should == :foo! }
    its(:arguments) { should be_empty }
    its(:receiver) { should be_nil }
    its(:proc_argument) { should be_nil }
  end

  context "when a word followed by ?" do
    let(:node) { ast("foo?") }
    its(:name) { should == :foo? }
    its(:arguments) { should be_empty }
    its(:receiver) { should be_nil }
    its(:proc_argument) { should be_nil }
  end

  context "when a word followed by some other symbol" do
    let(:node) { ast("foo.") }

    describe "#name" do
      it "raises UnknownMessageStructure" do
        expect { subject.name }.to raise_error(described_class::UnknownMessageStructure)
      end
    end

    its(:arguments) { should be_empty }
    its(:receiver) { should be_nil }
    its(:proc_argument) { should be_nil }
  end

  context "when a word with arguments" do
    let(:node) { ast("foo(a, b)") }
    its(:name) { should == :foo }
    its(:arguments) { should == [ast("a"), ast("b")] }
    its(:receiver) { should be_nil }
    its(:proc_argument) { should be_nil }
  end

  context "when a word followed by ! with arguments" do
    let(:node) { ast("foo!(a, b)") }
    its(:name) { should == :foo! }
    its(:arguments) { should == [ast("a"), ast("b")] }
    its(:receiver) { should be_nil }
    its(:proc_argument) { should be_nil }
  end

  context "when a word followed by ? with arguments" do
    let(:node) { ast("foo?(a, b)") }
    its(:name) { should == :foo? }
    its(:arguments) { should == [ast("a"), ast("b")] }
    its(:receiver) { should be_nil }
    its(:proc_argument) { should be_nil }
  end

  context "when a word with a proc argument" do
    let(:node) { ast("foo &blk") }
    its(:name) { should == :foo }
    its(:arguments) { should be_empty }
    its(:receiver) { should be_nil }
    its(:proc_argument) { should == ast("blk") }
  end

  context "when a word followed by ! with a proc argument" do
    let(:node) { ast("foo! &blk") }
    its(:name) { should == :foo! }
    its(:arguments) { should be_empty }
    its(:receiver) { should be_nil }
    its(:proc_argument) { should == ast("blk") }
  end

  context "when a word followed by ? with a proc argument" do
    let(:node) { ast("foo? &blk") }
    its(:name) { should == :foo? }
    its(:arguments) { should be_empty }
    its(:receiver) { should be_nil }
    its(:proc_argument) { should == ast("blk") }
  end

  context "when a word with arguments with a proc argument" do
    let(:node) { ast("foo(a, b) &blk") }
    its(:name) { should == :foo }
    its(:arguments) { should == [ast("a"), ast("b")] }
    its(:receiver) { should be_nil }
    its(:proc_argument) { should == ast("blk") }
  end

  context "when a word followed by ! with arguments with a proc argument" do
    let(:node) { ast("foo!(a, b) &blk") }
    its(:name) { should == :foo! }
    its(:arguments) { should == [ast("a"), ast("b")] }
    its(:receiver) { should be_nil }
    its(:proc_argument) { should == ast("blk") }
  end

  context "when a word followed by ? with arguments with a proc argument" do
    let(:node) { ast("foo?(a, b) &blk") }
    its(:name) { should == :foo? }
    its(:arguments) { should == [ast("a"), ast("b")] }
    its(:receiver) { should be_nil }
    its(:proc_argument) { should == ast("blk") }
  end

  context "when a node followed by a word" do
    let(:node) { ast("42 foo") }
    its(:name) { should == :foo }
    its(:arguments) { should be_empty }
    its(:receiver) { should == ast("42") }
    its(:proc_argument) { should be_nil }
  end

  context "when a node followed by a word followed by !" do
    let(:node) { ast("42 foo!") }
    its(:name) { should == :foo! }
    its(:arguments) { should be_empty }
    its(:receiver) { should == ast("42") }
    its(:proc_argument) { should be_nil }
  end

  context "when a node followed by a word followed by ?" do
    let(:node) { ast("42 foo?") }
    its(:name) { should == :foo? }
    its(:arguments) { should be_empty }
    its(:receiver) { should == ast("42") }
    its(:proc_argument) { should be_nil }
  end

  context "when a node followed by a word with arguments" do
    let(:node) { ast("42 foo(a, b)") }
    its(:name) { should == :foo }
    its(:arguments) { should == [ast("a"), ast("b")] }
    its(:receiver) { should == ast("42") }
    its(:proc_argument) { should be_nil }
  end

  context "when a node followed by a word followed by ! with arguments" do
    let(:node) { ast("42 foo!(a, b)") }
    its(:name) { should == :foo! }
    its(:arguments) { should == [ast("a"), ast("b")] }
    its(:receiver) { should == ast("42") }
    its(:proc_argument) { should be_nil }
  end

  context "when a node followed by a word followed by ? with arguments" do
    let(:node) { ast("42 foo?(a, b)") }
    its(:name) { should == :foo? }
    its(:arguments) { should == [ast("a"), ast("b")] }
    its(:receiver) { should == ast("42") }
    its(:proc_argument) { should be_nil }
  end

  context "when a node followed by a word with a proc argument" do
    let(:node) { ast("42 foo &blk") }
    its(:name) { should == :foo }
    its(:arguments) { should be_empty }
    its(:receiver) { should == ast("42") }
    its(:proc_argument) { should == ast("blk") }
  end

  context "when a node followed by a word followed by ! with a proc argument" do
    let(:node) { ast("42 foo! &blk") }
    its(:name) { should == :foo! }
    its(:arguments) { should be_empty }
    its(:receiver) { should == ast("42") }
    its(:proc_argument) { should == ast("blk") }
  end

  context "when a node followed by a word followed by ? with a proc argument" do
    let(:node) { ast("42 foo? &blk") }
    its(:name) { should == :foo? }
    its(:arguments) { should be_empty }
    its(:receiver) { should == ast("42") }
    its(:proc_argument) { should == ast("blk") }
  end

  context "when a node followed by a word with arguments with a proc argument" do
    let(:node) { ast("42 foo(a, b) &blk") }
    its(:name) { should == :foo }
    its(:arguments) { should == [ast("a"), ast("b")] }
    its(:receiver) { should == ast("42") }
    its(:proc_argument) { should == ast("blk") }
  end

  context "when a node followed by a word followed by ! with arguments with a proc argument" do
    let(:node) { ast("42 foo!(a, b) &blk") }
    its(:name) { should == :foo! }
    its(:arguments) { should == [ast("a"), ast("b")] }
    its(:receiver) { should == ast("42") }
    its(:proc_argument) { should == ast("blk") }
  end

  context "when a node followed by a word followed by ? with arguments with a proc argument" do
    let(:node) { ast("42 foo?(a, b) &blk") }
    its(:name) { should == :foo? }
    its(:arguments) { should == [ast("a"), ast("b")] }
    its(:receiver) { should == ast("42") }
    its(:proc_argument) { should == ast("blk") }
  end
end
