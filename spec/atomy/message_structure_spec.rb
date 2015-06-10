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
    its(:block) { should be_nil }
    its(:splat_argument) { should be_nil }
  end

  context "when a word" do
    let(:node) { ast("foo") }
    its(:name) { should == :foo }
    its(:arguments) { should be_empty }
    its(:receiver) { should be_nil }
    its(:proc_argument) { should be_nil }
    its(:block) { should be_nil }
    its(:splat_argument) { should be_nil }
  end

  context "when a word followed by !" do
    let(:node) { ast("foo!") }
    its(:name) { should == :foo! }
    its(:arguments) { should be_empty }
    its(:receiver) { should be_nil }
    its(:proc_argument) { should be_nil }
    its(:block) { should be_nil }
    its(:splat_argument) { should be_nil }
  end

  context "when a word followed by ?" do
    let(:node) { ast("foo?") }
    its(:name) { should == :foo? }
    its(:arguments) { should be_empty }
    its(:receiver) { should be_nil }
    its(:proc_argument) { should be_nil }
    its(:block) { should be_nil }
    its(:splat_argument) { should be_nil }
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
    its(:block) { should be_nil }
    its(:splat_argument) { should be_nil }
  end

  context "when a word with arguments" do
    let(:node) { ast("foo(a, b)") }
    its(:name) { should == :foo }
    its(:arguments) { should == [ast("a"), ast("b")] }
    its(:receiver) { should be_nil }
    its(:proc_argument) { should be_nil }
    its(:block) { should be_nil }
    its(:splat_argument) { should be_nil }
  end

  context "when a word with arguments with a splat" do
    let(:node) { ast("foo(a, b, *c)") }
    its(:name) { should == :foo }
    its(:arguments) { should == [ast("a"), ast("b")] }
    its(:receiver) { should be_nil }
    its(:proc_argument) { should be_nil }
    its(:block) { should be_nil }
    its(:splat_argument) { should == ast("c") }
  end

  context "when a word followed by ! with arguments" do
    let(:node) { ast("foo!(a, b)") }
    its(:name) { should == :foo! }
    its(:arguments) { should == [ast("a"), ast("b")] }
    its(:receiver) { should be_nil }
    its(:proc_argument) { should be_nil }
    its(:block) { should be_nil }
    its(:splat_argument) { should be_nil }
  end

  context "when a word followed by ? with arguments" do
    let(:node) { ast("foo?(a, b)") }
    its(:name) { should == :foo? }
    its(:arguments) { should == [ast("a"), ast("b")] }
    its(:receiver) { should be_nil }
    its(:proc_argument) { should be_nil }
    its(:block) { should be_nil }
    its(:splat_argument) { should be_nil }
  end

  context "when a word with a proc argument" do
    let(:node) { ast("foo &blk") }
    its(:name) { should == :foo }
    its(:arguments) { should be_empty }
    its(:receiver) { should be_nil }
    its(:proc_argument) { should == ast("blk") }
    its(:block) { should be_nil }
    its(:splat_argument) { should be_nil }
  end

  context "when a word followed by ! with a proc argument" do
    let(:node) { ast("foo! &blk") }
    its(:name) { should == :foo! }
    its(:arguments) { should be_empty }
    its(:receiver) { should be_nil }
    its(:proc_argument) { should == ast("blk") }
    its(:block) { should be_nil }
    its(:splat_argument) { should be_nil }
  end

  context "when a word followed by ? with a proc argument" do
    let(:node) { ast("foo? &blk") }
    its(:name) { should == :foo? }
    its(:arguments) { should be_empty }
    its(:receiver) { should be_nil }
    its(:proc_argument) { should == ast("blk") }
    its(:block) { should be_nil }
    its(:splat_argument) { should be_nil }
  end

  context "when a word with arguments with a proc argument" do
    let(:node) { ast("foo(a, b) &blk") }
    its(:name) { should == :foo }
    its(:arguments) { should == [ast("a"), ast("b")] }
    its(:receiver) { should be_nil }
    its(:proc_argument) { should == ast("blk") }
    its(:block) { should be_nil }
    its(:splat_argument) { should be_nil }
  end

  context "when a word followed by ! with arguments with a proc argument" do
    let(:node) { ast("foo!(a, b) &blk") }
    its(:name) { should == :foo! }
    its(:arguments) { should == [ast("a"), ast("b")] }
    its(:receiver) { should be_nil }
    its(:proc_argument) { should == ast("blk") }
    its(:block) { should be_nil }
    its(:splat_argument) { should be_nil }
  end

  context "when a word followed by ? with arguments with a proc argument" do
    let(:node) { ast("foo?(a, b) &blk") }
    its(:name) { should == :foo? }
    its(:arguments) { should == [ast("a"), ast("b")] }
    its(:receiver) { should be_nil }
    its(:proc_argument) { should == ast("blk") }
    its(:block) { should be_nil }
    its(:splat_argument) { should be_nil }
  end

  context "when a word with a block that has no arguments" do
    let(:node) { ast("foo: a + b") }
    its(:name) { should == :foo }
    its(:arguments) { should be_empty }
    its(:receiver) { should be_nil }
    its(:proc_argument) { should be_nil }
    its(:block) { should == ast("{ a + b }") }
    its(:splat_argument) { should be_nil }
  end

  context "when a word followed by ! with a block that has no arguments" do
    let(:node) { ast("foo!: a + b") }
    its(:name) { should == :foo! }
    its(:arguments) { should be_empty }
    its(:receiver) { should be_nil }
    its(:proc_argument) { should be_nil }
    its(:block) { should == ast("{ a + b }") }
    its(:splat_argument) { should be_nil }
  end

  context "when a word followed by ? with a block that has no arguments" do
    let(:node) { ast("foo?: a + b") }
    its(:name) { should == :foo? }
    its(:arguments) { should be_empty }
    its(:receiver) { should be_nil }
    its(:proc_argument) { should be_nil }
    its(:block) { should == ast("{ a + b }") }
    its(:splat_argument) { should be_nil }
  end

  context "when a word with arguments with a block that has no arguments" do
    let(:node) { ast("foo(a, b): a + b") }
    its(:name) { should == :foo }
    its(:arguments) { should == [ast("a"), ast("b")] }
    its(:receiver) { should be_nil }
    its(:proc_argument) { should be_nil }
    its(:block) { should == ast("{ a + b }") }
    its(:splat_argument) { should be_nil }
  end

  context "when a word followed by ! with arguments with a block that has no arguments" do
    let(:node) { ast("foo!(a, b): a + b") }
    its(:name) { should == :foo! }
    its(:arguments) { should == [ast("a"), ast("b")] }
    its(:receiver) { should be_nil }
    its(:proc_argument) { should be_nil }
    its(:block) { should == ast("{ a + b }") }
    its(:splat_argument) { should be_nil }
  end

  context "when a word followed by ? with arguments with a block that has no arguments" do
    let(:node) { ast("foo?(a, b): a + b") }
    its(:name) { should == :foo? }
    its(:arguments) { should == [ast("a"), ast("b")] }
    its(:receiver) { should be_nil }
    its(:proc_argument) { should be_nil }
    its(:block) { should == ast("{ a + b }") }
    its(:splat_argument) { should be_nil }
  end

  context "when a word with a block that has arguments" do
    let(:node) { ast("foo [a, b]: a + b") }
    its(:name) { should == :foo }
    its(:arguments) { should be_empty }
    its(:receiver) { should be_nil }
    its(:proc_argument) { should be_nil }
    its(:block) { should == ast("[a, b] { a + b }") }
    its(:splat_argument) { should be_nil }
  end

  context "when a word followed by ! with a block that has arguments" do
    let(:node) { ast("foo! [a, b]: a + b") }
    its(:name) { should == :foo! }
    its(:arguments) { should be_empty }
    its(:receiver) { should be_nil }
    its(:proc_argument) { should be_nil }
    its(:block) { should == ast("[a, b] { a + b }") }
    its(:splat_argument) { should be_nil }
  end

  context "when a word followed by ? with a block that has arguments" do
    let(:node) { ast("foo? [a, b]: a + b") }
    its(:name) { should == :foo? }
    its(:arguments) { should be_empty }
    its(:receiver) { should be_nil }
    its(:proc_argument) { should be_nil }
    its(:block) { should == ast("[a, b] { a + b }") }
    its(:splat_argument) { should be_nil }
  end

  context "when a word with arguments with a block that has arguments" do
    let(:node) { ast("foo(a, b) [a, b]: a + b") }
    its(:name) { should == :foo }
    its(:arguments) { should == [ast("a"), ast("b")] }
    its(:receiver) { should be_nil }
    its(:proc_argument) { should be_nil }
    its(:block) { should == ast("[a, b] { a + b }") }
    its(:splat_argument) { should be_nil }
  end

  context "when a word followed by ! with arguments with a block that has arguments" do
    let(:node) { ast("foo!(a, b) [a, b]: a + b") }
    its(:name) { should == :foo! }
    its(:arguments) { should == [ast("a"), ast("b")] }
    its(:receiver) { should be_nil }
    its(:proc_argument) { should be_nil }
    its(:block) { should == ast("[a, b] { a + b }") }
    its(:splat_argument) { should be_nil }
  end

  context "when a word followed by ? with arguments with a block that has arguments" do
    let(:node) { ast("foo?(a, b) [a, b]: a + b") }
    its(:name) { should == :foo? }
    its(:arguments) { should == [ast("a"), ast("b")] }
    its(:receiver) { should be_nil }
    its(:proc_argument) { should be_nil }
    its(:block) { should == ast("[a, b] { a + b }") }
    its(:splat_argument) { should be_nil }
  end

  context "when a node followed by a word" do
    let(:node) { ast("42 foo") }
    its(:name) { should == :foo }
    its(:arguments) { should be_empty }
    its(:receiver) { should == ast("42") }
    its(:proc_argument) { should be_nil }
    its(:block) { should be_nil }
    its(:splat_argument) { should be_nil }
  end

  context "when a node followed by a word followed by !" do
    let(:node) { ast("42 foo!") }
    its(:name) { should == :foo! }
    its(:arguments) { should be_empty }
    its(:receiver) { should == ast("42") }
    its(:proc_argument) { should be_nil }
    its(:block) { should be_nil }
    its(:splat_argument) { should be_nil }
  end

  context "when a node followed by a word followed by ?" do
    let(:node) { ast("42 foo?") }
    its(:name) { should == :foo? }
    its(:arguments) { should be_empty }
    its(:receiver) { should == ast("42") }
    its(:proc_argument) { should be_nil }
    its(:block) { should be_nil }
    its(:splat_argument) { should be_nil }
  end

  context "when a node followed by a word with arguments" do
    let(:node) { ast("42 foo(a, b)") }
    its(:name) { should == :foo }
    its(:arguments) { should == [ast("a"), ast("b")] }
    its(:receiver) { should == ast("42") }
    its(:proc_argument) { should be_nil }
    its(:block) { should be_nil }
    its(:splat_argument) { should be_nil }
  end

  context "when a node followed by a word followed by ! with arguments" do
    let(:node) { ast("42 foo!(a, b)") }
    its(:name) { should == :foo! }
    its(:arguments) { should == [ast("a"), ast("b")] }
    its(:receiver) { should == ast("42") }
    its(:proc_argument) { should be_nil }
    its(:block) { should be_nil }
    its(:splat_argument) { should be_nil }
  end

  context "when a node followed by a word followed by ? with arguments" do
    let(:node) { ast("42 foo?(a, b)") }
    its(:name) { should == :foo? }
    its(:arguments) { should == [ast("a"), ast("b")] }
    its(:receiver) { should == ast("42") }
    its(:proc_argument) { should be_nil }
    its(:block) { should be_nil }
    its(:splat_argument) { should be_nil }
  end

  context "when a node followed by a word with a proc argument" do
    let(:node) { ast("42 foo &blk") }
    its(:name) { should == :foo }
    its(:arguments) { should be_empty }
    its(:receiver) { should == ast("42") }
    its(:proc_argument) { should == ast("blk") }
    its(:block) { should be_nil }
    its(:splat_argument) { should be_nil }
  end

  context "when a node followed by a word followed by ! with a proc argument" do
    let(:node) { ast("42 foo! &blk") }
    its(:name) { should == :foo! }
    its(:arguments) { should be_empty }
    its(:receiver) { should == ast("42") }
    its(:proc_argument) { should == ast("blk") }
    its(:block) { should be_nil }
    its(:splat_argument) { should be_nil }
  end

  context "when a node followed by a word followed by ? with a proc argument" do
    let(:node) { ast("42 foo? &blk") }
    its(:name) { should == :foo? }
    its(:arguments) { should be_empty }
    its(:receiver) { should == ast("42") }
    its(:proc_argument) { should == ast("blk") }
    its(:block) { should be_nil }
    its(:splat_argument) { should be_nil }
  end

  context "when a node followed by a word with arguments with a proc argument" do
    let(:node) { ast("42 foo(a, b) &blk") }
    its(:name) { should == :foo }
    its(:arguments) { should == [ast("a"), ast("b")] }
    its(:receiver) { should == ast("42") }
    its(:proc_argument) { should == ast("blk") }
    its(:block) { should be_nil }
    its(:splat_argument) { should be_nil }
  end

  context "when a node followed by a word followed by ! with arguments with a proc argument" do
    let(:node) { ast("42 foo!(a, b) &blk") }
    its(:name) { should == :foo! }
    its(:arguments) { should == [ast("a"), ast("b")] }
    its(:receiver) { should == ast("42") }
    its(:proc_argument) { should == ast("blk") }
    its(:block) { should be_nil }
    its(:splat_argument) { should be_nil }
  end

  context "when a node followed by a word followed by ? with arguments with a proc argument" do
    let(:node) { ast("42 foo?(a, b) &blk") }
    its(:name) { should == :foo? }
    its(:arguments) { should == [ast("a"), ast("b")] }
    its(:receiver) { should == ast("42") }
    its(:proc_argument) { should == ast("blk") }
    its(:block) { should be_nil }
    its(:splat_argument) { should be_nil }
  end

  context "when a node followed by a word with a block that has no arguments" do
    let(:node) { ast("42 foo: a + b") }
    its(:name) { should == :foo }
    its(:arguments) { should be_empty }
    its(:receiver) { should == ast("42") }
    its(:proc_argument) { should be_nil }
    its(:block) { should == ast("{ a + b }") }
    its(:splat_argument) { should be_nil }
  end

  context "when a node followed by a word followed by ! with a block that has no arguments" do
    let(:node) { ast("42 foo!: a + b") }
    its(:name) { should == :foo! }
    its(:arguments) { should be_empty }
    its(:receiver) { should == ast("42") }
    its(:proc_argument) { should be_nil }
    its(:block) { should == ast("{ a + b }") }
    its(:splat_argument) { should be_nil }
  end

  context "when a node followed by a word followed by ? with a block that has no arguments" do
    let(:node) { ast("42 foo?: a + b") }
    its(:name) { should == :foo? }
    its(:arguments) { should be_empty }
    its(:receiver) { should == ast("42") }
    its(:proc_argument) { should be_nil }
    its(:block) { should == ast("{ a + b }") }
    its(:splat_argument) { should be_nil }
  end

  context "when a node followed by a word with arguments with a block that has no arguments" do
    let(:node) { ast("42 foo(a, b): a + b") }
    its(:name) { should == :foo }
    its(:arguments) { should == [ast("a"), ast("b")] }
    its(:receiver) { should == ast("42") }
    its(:proc_argument) { should be_nil }
    its(:block) { should == ast("{ a + b }") }
    its(:splat_argument) { should be_nil }
  end

  context "when a node followed by a word followed by ! with arguments with a block that has no arguments" do
    let(:node) { ast("42 foo!(a, b): a + b") }
    its(:name) { should == :foo! }
    its(:arguments) { should == [ast("a"), ast("b")] }
    its(:receiver) { should == ast("42") }
    its(:proc_argument) { should be_nil }
    its(:block) { should == ast("{ a + b }") }
    its(:splat_argument) { should be_nil }
  end

  context "when a node followed by a word followed by ? with arguments with a block that has no arguments" do
    let(:node) { ast("42 foo?(a, b): a + b") }
    its(:name) { should == :foo? }
    its(:arguments) { should == [ast("a"), ast("b")] }
    its(:receiver) { should == ast("42") }
    its(:proc_argument) { should be_nil }
    its(:block) { should == ast("{ a + b }") }
    its(:splat_argument) { should be_nil }
  end

  context "when a node followed by a word with a block that has arguments" do
    let(:node) { ast("42 foo [a, b]: a + b") }
    its(:name) { should == :foo }
    its(:arguments) { should be_empty }
    its(:receiver) { should == ast("42") }
    its(:proc_argument) { should be_nil }
    its(:block) { should == ast("[a, b] { a + b }") }
    its(:splat_argument) { should be_nil }
  end

  context "when a node followed by a word followed by ! with a block that has arguments" do
    let(:node) { ast("42 foo! [a, b]: a + b") }
    its(:name) { should == :foo! }
    its(:arguments) { should be_empty }
    its(:receiver) { should == ast("42") }
    its(:proc_argument) { should be_nil }
    its(:block) { should == ast("[a, b] { a + b }") }
    its(:splat_argument) { should be_nil }
  end

  context "when a node followed by a word followed by ? with a block that has arguments" do
    let(:node) { ast("42 foo? [a, b]: a + b") }
    its(:name) { should == :foo? }
    its(:arguments) { should be_empty }
    its(:receiver) { should == ast("42") }
    its(:proc_argument) { should be_nil }
    its(:block) { should == ast("[a, b] { a + b }") }
    its(:splat_argument) { should be_nil }
  end

  context "when a node followed by a word with arguments with a block that has arguments" do
    let(:node) { ast("42 foo(a, b) [a, b]: a + b") }
    its(:name) { should == :foo }
    its(:arguments) { should == [ast("a"), ast("b")] }
    its(:receiver) { should == ast("42") }
    its(:proc_argument) { should be_nil }
    its(:block) { should == ast("[a, b] { a + b }") }
    its(:splat_argument) { should be_nil }
  end

  context "when a node followed by a word followed by ! with arguments with a block that has arguments" do
    let(:node) { ast("42 foo!(a, b) [a, b]: a + b") }
    its(:name) { should == :foo! }
    its(:arguments) { should == [ast("a"), ast("b")] }
    its(:receiver) { should == ast("42") }
    its(:proc_argument) { should be_nil }
    its(:block) { should == ast("[a, b] { a + b }") }
    its(:splat_argument) { should be_nil }
  end

  context "when a node followed by a word followed by ? with arguments with a block that has arguments" do
    let(:node) { ast("42 foo?(a, b) [a, b]: a + b") }
    its(:name) { should == :foo? }
    its(:arguments) { should == [ast("a"), ast("b")] }
    its(:receiver) { should == ast("42") }
    its(:proc_argument) { should be_nil }
    its(:block) { should == ast("[a, b] { a + b }") }
    its(:splat_argument) { should be_nil }
  end

  context "when a node followed by a list" do
    let(:node) { ast("42 [a, b]") }
    its(:name) { should == :[] }
    its(:arguments) { should == [ast("a"), ast("b")] }
    its(:receiver) { should == ast("42") }
    its(:proc_argument) { should be_nil }
    its(:block) { should be_nil }
    its(:splat_argument) { should be_nil }
  end

  context "when an infix node" do
    let(:node) { ast("a + b") }
    its(:name) { should == :+ }
    its(:arguments) { should == [ast("b")] }
    its(:receiver) { should == ast("a") }
    its(:proc_argument) { should be_nil }
    its(:block) { should be_nil }
  end

  context "when a prefix node" do
    let(:node) { ast("^foo") }
    its(:name) { should == :"^@" }
    its(:arguments) { should be_empty }
    its(:receiver) { should == ast("foo") }
    its(:proc_argument) { should be_nil }
    its(:block) { should be_nil }
    its(:splat_argument) { should be_nil }

    context "wrapping a suffix node" do
      let(:node) { ast("^foo?") }
      its(:name) { should == :"^@" }
      its(:arguments) { should be_empty }
      its(:receiver) { should == ast("foo?") }
      its(:proc_argument) { should be_nil }
      its(:block) { should be_nil }
      its(:splat_argument) { should be_nil }
    end
  end

  context "when a constant" do
    let(:node) { ast("Foo") }

    describe "#name" do
      it "raises UnknownMessageStructure" do
        expect { subject.name }.to raise_error(described_class::UnknownMessageStructure)
      end
    end

    its(:arguments) { should be_empty }
    its(:receiver) { should be_nil }
    its(:proc_argument) { should be_nil }
    its(:block) { should be_nil }
    its(:splat_argument) { should be_nil }
  end

  context "when a constant followed by !" do
    let(:node) { ast("Foo!") }
    its(:name) { should == :Foo! }
    its(:arguments) { should be_empty }
    its(:receiver) { should be_nil }
    its(:proc_argument) { should be_nil }
    its(:block) { should be_nil }
    its(:splat_argument) { should be_nil }
  end

  context "when a constant followed by ?" do
    let(:node) { ast("Foo?") }
    its(:name) { should == :Foo? }
    its(:arguments) { should be_empty }
    its(:receiver) { should be_nil }
    its(:proc_argument) { should be_nil }
    its(:block) { should be_nil }
    its(:splat_argument) { should be_nil }
  end

  context "when a constant with arguments" do
    let(:node) { ast("Foo(a, b)") }
    its(:name) { should == :Foo }
    its(:arguments) { should == [ast("a"), ast("b")] }
    its(:receiver) { should be_nil }
    its(:proc_argument) { should be_nil }
    its(:block) { should be_nil }
    its(:splat_argument) { should be_nil }
  end

  context "when a constant with arguments with a splat" do
    let(:node) { ast("Foo(a, b, *c)") }
    its(:name) { should == :Foo }
    its(:arguments) { should == [ast("a"), ast("b")] }
    its(:receiver) { should be_nil }
    its(:proc_argument) { should be_nil }
    its(:block) { should be_nil }
    its(:splat_argument) { should == ast("c") }
  end

  context "when a constant followed by ! with arguments" do
    let(:node) { ast("Foo!(a, b)") }
    its(:name) { should == :Foo! }
    its(:arguments) { should == [ast("a"), ast("b")] }
    its(:receiver) { should be_nil }
    its(:proc_argument) { should be_nil }
    its(:block) { should be_nil }
    its(:splat_argument) { should be_nil }
  end

  context "when a constant followed by ? with arguments" do
    let(:node) { ast("Foo?(a, b)") }
    its(:name) { should == :Foo? }
    its(:arguments) { should == [ast("a"), ast("b")] }
    its(:receiver) { should be_nil }
    its(:proc_argument) { should be_nil }
    its(:block) { should be_nil }
    its(:splat_argument) { should be_nil }
  end

  context "when a constant with a proc argument" do
    let(:node) { ast("Foo &blk") }
    its(:name) { should == :Foo }
    its(:arguments) { should be_empty }
    its(:receiver) { should be_nil }
    its(:proc_argument) { should == ast("blk") }
    its(:block) { should be_nil }
    its(:splat_argument) { should be_nil }
  end

  context "when a constant followed by ! with a proc argument" do
    let(:node) { ast("Foo! &blk") }
    its(:name) { should == :Foo! }
    its(:arguments) { should be_empty }
    its(:receiver) { should be_nil }
    its(:proc_argument) { should == ast("blk") }
    its(:block) { should be_nil }
    its(:splat_argument) { should be_nil }
  end

  context "when a constant followed by ? with a proc argument" do
    let(:node) { ast("Foo? &blk") }
    its(:name) { should == :Foo? }
    its(:arguments) { should be_empty }
    its(:receiver) { should be_nil }
    its(:proc_argument) { should == ast("blk") }
    its(:block) { should be_nil }
    its(:splat_argument) { should be_nil }
  end

  context "when a constant with arguments with a proc argument" do
    let(:node) { ast("Foo(a, b) &blk") }
    its(:name) { should == :Foo }
    its(:arguments) { should == [ast("a"), ast("b")] }
    its(:receiver) { should be_nil }
    its(:proc_argument) { should == ast("blk") }
    its(:block) { should be_nil }
    its(:splat_argument) { should be_nil }
  end

  context "when a constant followed by ! with arguments with a proc argument" do
    let(:node) { ast("Foo!(a, b) &blk") }
    its(:name) { should == :Foo! }
    its(:arguments) { should == [ast("a"), ast("b")] }
    its(:receiver) { should be_nil }
    its(:proc_argument) { should == ast("blk") }
    its(:block) { should be_nil }
    its(:splat_argument) { should be_nil }
  end

  context "when a constant followed by ? with arguments with a proc argument" do
    let(:node) { ast("Foo?(a, b) &blk") }
    its(:name) { should == :Foo? }
    its(:arguments) { should == [ast("a"), ast("b")] }
    its(:receiver) { should be_nil }
    its(:proc_argument) { should == ast("blk") }
    its(:block) { should be_nil }
    its(:splat_argument) { should be_nil }
  end

  context "when a constant with a block that has no arguments" do
    let(:node) { ast("Foo: a + b") }
    its(:name) { should == :Foo }
    its(:arguments) { should be_empty }
    its(:receiver) { should be_nil }
    its(:proc_argument) { should be_nil }
    its(:block) { should == ast("{ a + b }") }
    its(:splat_argument) { should be_nil }
  end

  context "when a constant followed by ! with a block that has no arguments" do
    let(:node) { ast("Foo!: a + b") }
    its(:name) { should == :Foo! }
    its(:arguments) { should be_empty }
    its(:receiver) { should be_nil }
    its(:proc_argument) { should be_nil }
    its(:block) { should == ast("{ a + b }") }
    its(:splat_argument) { should be_nil }
  end

  context "when a constant followed by ? with a block that has no arguments" do
    let(:node) { ast("Foo?: a + b") }
    its(:name) { should == :Foo? }
    its(:arguments) { should be_empty }
    its(:receiver) { should be_nil }
    its(:proc_argument) { should be_nil }
    its(:block) { should == ast("{ a + b }") }
    its(:splat_argument) { should be_nil }
  end

  context "when a constant with arguments with a block that has no arguments" do
    let(:node) { ast("Foo(a, b): a + b") }
    its(:name) { should == :Foo }
    its(:arguments) { should == [ast("a"), ast("b")] }
    its(:receiver) { should be_nil }
    its(:proc_argument) { should be_nil }
    its(:block) { should == ast("{ a + b }") }
    its(:splat_argument) { should be_nil }
  end

  context "when a constant followed by ! with arguments with a block that has no arguments" do
    let(:node) { ast("Foo!(a, b): a + b") }
    its(:name) { should == :Foo! }
    its(:arguments) { should == [ast("a"), ast("b")] }
    its(:receiver) { should be_nil }
    its(:proc_argument) { should be_nil }
    its(:block) { should == ast("{ a + b }") }
    its(:splat_argument) { should be_nil }
  end

  context "when a constant followed by ? with arguments with a block that has no arguments" do
    let(:node) { ast("Foo?(a, b): a + b") }
    its(:name) { should == :Foo? }
    its(:arguments) { should == [ast("a"), ast("b")] }
    its(:receiver) { should be_nil }
    its(:proc_argument) { should be_nil }
    its(:block) { should == ast("{ a + b }") }
    its(:splat_argument) { should be_nil }
  end

  context "when a constant with a block that has arguments" do
    let(:node) { ast("Foo [a, b]: a + b") }
    its(:name) { should == :Foo }
    its(:arguments) { should be_empty }
    its(:receiver) { should be_nil }
    its(:proc_argument) { should be_nil }
    its(:block) { should == ast("[a, b] { a + b }") }
    its(:splat_argument) { should be_nil }
  end

  context "when a constant followed by ! with a block that has arguments" do
    let(:node) { ast("Foo! [a, b]: a + b") }
    its(:name) { should == :Foo! }
    its(:arguments) { should be_empty }
    its(:receiver) { should be_nil }
    its(:proc_argument) { should be_nil }
    its(:block) { should == ast("[a, b] { a + b }") }
    its(:splat_argument) { should be_nil }
  end

  context "when a constant followed by ? with a block that has arguments" do
    let(:node) { ast("Foo? [a, b]: a + b") }
    its(:name) { should == :Foo? }
    its(:arguments) { should be_empty }
    its(:receiver) { should be_nil }
    its(:proc_argument) { should be_nil }
    its(:block) { should == ast("[a, b] { a + b }") }
    its(:splat_argument) { should be_nil }
  end

  context "when a constant with arguments with a block that has arguments" do
    let(:node) { ast("Foo(a, b) [a, b]: a + b") }
    its(:name) { should == :Foo }
    its(:arguments) { should == [ast("a"), ast("b")] }
    its(:receiver) { should be_nil }
    its(:proc_argument) { should be_nil }
    its(:block) { should == ast("[a, b] { a + b }") }
    its(:splat_argument) { should be_nil }
  end

  context "when a constant followed by ! with arguments with a block that has arguments" do
    let(:node) { ast("Foo!(a, b) [a, b]: a + b") }
    its(:name) { should == :Foo! }
    its(:arguments) { should == [ast("a"), ast("b")] }
    its(:receiver) { should be_nil }
    its(:proc_argument) { should be_nil }
    its(:block) { should == ast("[a, b] { a + b }") }
    its(:splat_argument) { should be_nil }
  end

  context "when a constant followed by ? with arguments with a block that has arguments" do
    let(:node) { ast("Foo?(a, b) [a, b]: a + b") }
    its(:name) { should == :Foo? }
    its(:arguments) { should == [ast("a"), ast("b")] }
    its(:receiver) { should be_nil }
    its(:proc_argument) { should be_nil }
    its(:block) { should == ast("[a, b] { a + b }") }
    its(:splat_argument) { should be_nil }
  end

  context "when a node followed by a constant" do
    let(:node) { ast("42 Foo") }
    its(:name) { should == :Foo }
    its(:arguments) { should be_empty }
    its(:receiver) { should == ast("42") }
    its(:proc_argument) { should be_nil }
    its(:block) { should be_nil }
    its(:splat_argument) { should be_nil }
  end

  context "when a node followed by a constant followed by !" do
    let(:node) { ast("42 Foo!") }
    its(:name) { should == :Foo! }
    its(:arguments) { should be_empty }
    its(:receiver) { should == ast("42") }
    its(:proc_argument) { should be_nil }
    its(:block) { should be_nil }
    its(:splat_argument) { should be_nil }
  end

  context "when a node followed by a constant followed by ?" do
    let(:node) { ast("42 Foo?") }
    its(:name) { should == :Foo? }
    its(:arguments) { should be_empty }
    its(:receiver) { should == ast("42") }
    its(:proc_argument) { should be_nil }
    its(:block) { should be_nil }
    its(:splat_argument) { should be_nil }
  end

  context "when a node followed by a constant with arguments" do
    let(:node) { ast("42 Foo(a, b)") }
    its(:name) { should == :Foo }
    its(:arguments) { should == [ast("a"), ast("b")] }
    its(:receiver) { should == ast("42") }
    its(:proc_argument) { should be_nil }
    its(:block) { should be_nil }
    its(:splat_argument) { should be_nil }
  end

  context "when a node followed by a constant followed by ! with arguments" do
    let(:node) { ast("42 Foo!(a, b)") }
    its(:name) { should == :Foo! }
    its(:arguments) { should == [ast("a"), ast("b")] }
    its(:receiver) { should == ast("42") }
    its(:proc_argument) { should be_nil }
    its(:block) { should be_nil }
    its(:splat_argument) { should be_nil }
  end

  context "when a node followed by a constant followed by ? with arguments" do
    let(:node) { ast("42 Foo?(a, b)") }
    its(:name) { should == :Foo? }
    its(:arguments) { should == [ast("a"), ast("b")] }
    its(:receiver) { should == ast("42") }
    its(:proc_argument) { should be_nil }
    its(:block) { should be_nil }
    its(:splat_argument) { should be_nil }
  end

  context "when a node followed by a constant with a proc argument" do
    let(:node) { ast("42 Foo &blk") }
    its(:name) { should == :Foo }
    its(:arguments) { should be_empty }
    its(:receiver) { should == ast("42") }
    its(:proc_argument) { should == ast("blk") }
    its(:block) { should be_nil }
    its(:splat_argument) { should be_nil }
  end

  context "when a node followed by a constant followed by ! with a proc argument" do
    let(:node) { ast("42 Foo! &blk") }
    its(:name) { should == :Foo! }
    its(:arguments) { should be_empty }
    its(:receiver) { should == ast("42") }
    its(:proc_argument) { should == ast("blk") }
    its(:block) { should be_nil }
    its(:splat_argument) { should be_nil }
  end

  context "when a node followed by a constant followed by ? with a proc argument" do
    let(:node) { ast("42 Foo? &blk") }
    its(:name) { should == :Foo? }
    its(:arguments) { should be_empty }
    its(:receiver) { should == ast("42") }
    its(:proc_argument) { should == ast("blk") }
    its(:block) { should be_nil }
    its(:splat_argument) { should be_nil }
  end

  context "when a node followed by a constant with arguments with a proc argument" do
    let(:node) { ast("42 Foo(a, b) &blk") }
    its(:name) { should == :Foo }
    its(:arguments) { should == [ast("a"), ast("b")] }
    its(:receiver) { should == ast("42") }
    its(:proc_argument) { should == ast("blk") }
    its(:block) { should be_nil }
    its(:splat_argument) { should be_nil }
  end

  context "when a node followed by a constant followed by ! with arguments with a proc argument" do
    let(:node) { ast("42 Foo!(a, b) &blk") }
    its(:name) { should == :Foo! }
    its(:arguments) { should == [ast("a"), ast("b")] }
    its(:receiver) { should == ast("42") }
    its(:proc_argument) { should == ast("blk") }
    its(:block) { should be_nil }
    its(:splat_argument) { should be_nil }
  end

  context "when a node followed by a constant followed by ? with arguments with a proc argument" do
    let(:node) { ast("42 Foo?(a, b) &blk") }
    its(:name) { should == :Foo? }
    its(:arguments) { should == [ast("a"), ast("b")] }
    its(:receiver) { should == ast("42") }
    its(:proc_argument) { should == ast("blk") }
    its(:block) { should be_nil }
    its(:splat_argument) { should be_nil }
  end

  context "when a node followed by a constant with a block that has no arguments" do
    let(:node) { ast("42 Foo: a + b") }
    its(:name) { should == :Foo }
    its(:arguments) { should be_empty }
    its(:receiver) { should == ast("42") }
    its(:proc_argument) { should be_nil }
    its(:block) { should == ast("{ a + b }") }
    its(:splat_argument) { should be_nil }
  end

  context "when a node followed by a constant followed by ! with a block that has no arguments" do
    let(:node) { ast("42 Foo!: a + b") }
    its(:name) { should == :Foo! }
    its(:arguments) { should be_empty }
    its(:receiver) { should == ast("42") }
    its(:proc_argument) { should be_nil }
    its(:block) { should == ast("{ a + b }") }
    its(:splat_argument) { should be_nil }
  end

  context "when a node followed by a constant followed by ? with a block that has no arguments" do
    let(:node) { ast("42 Foo?: a + b") }
    its(:name) { should == :Foo? }
    its(:arguments) { should be_empty }
    its(:receiver) { should == ast("42") }
    its(:proc_argument) { should be_nil }
    its(:block) { should == ast("{ a + b }") }
    its(:splat_argument) { should be_nil }
  end

  context "when a node followed by a constant with arguments with a block that has no arguments" do
    let(:node) { ast("42 Foo(a, b): a + b") }
    its(:name) { should == :Foo }
    its(:arguments) { should == [ast("a"), ast("b")] }
    its(:receiver) { should == ast("42") }
    its(:proc_argument) { should be_nil }
    its(:block) { should == ast("{ a + b }") }
    its(:splat_argument) { should be_nil }
  end

  context "when a node followed by a constant followed by ! with arguments with a block that has no arguments" do
    let(:node) { ast("42 Foo!(a, b): a + b") }
    its(:name) { should == :Foo! }
    its(:arguments) { should == [ast("a"), ast("b")] }
    its(:receiver) { should == ast("42") }
    its(:proc_argument) { should be_nil }
    its(:block) { should == ast("{ a + b }") }
    its(:splat_argument) { should be_nil }
  end

  context "when a node followed by a constant followed by ? with arguments with a block that has no arguments" do
    let(:node) { ast("42 Foo?(a, b): a + b") }
    its(:name) { should == :Foo? }
    its(:arguments) { should == [ast("a"), ast("b")] }
    its(:receiver) { should == ast("42") }
    its(:proc_argument) { should be_nil }
    its(:block) { should == ast("{ a + b }") }
    its(:splat_argument) { should be_nil }
  end

  context "when a node followed by a constant with a block that has arguments" do
    let(:node) { ast("42 Foo [a, b]: a + b") }
    its(:name) { should == :Foo }
    its(:arguments) { should be_empty }
    its(:receiver) { should == ast("42") }
    its(:proc_argument) { should be_nil }
    its(:block) { should == ast("[a, b] { a + b }") }
    its(:splat_argument) { should be_nil }
  end

  context "when a node followed by a constant followed by ! with a block that has arguments" do
    let(:node) { ast("42 Foo! [a, b]: a + b") }
    its(:name) { should == :Foo! }
    its(:arguments) { should be_empty }
    its(:receiver) { should == ast("42") }
    its(:proc_argument) { should be_nil }
    its(:block) { should == ast("[a, b] { a + b }") }
    its(:splat_argument) { should be_nil }
  end

  context "when a node followed by a constant followed by ? with a block that has arguments" do
    let(:node) { ast("42 Foo? [a, b]: a + b") }
    its(:name) { should == :Foo? }
    its(:arguments) { should be_empty }
    its(:receiver) { should == ast("42") }
    its(:proc_argument) { should be_nil }
    its(:block) { should == ast("[a, b] { a + b }") }
    its(:splat_argument) { should be_nil }
  end

  context "when a node followed by a constant with arguments with a block that has arguments" do
    let(:node) { ast("42 Foo(a, b) [a, b]: a + b") }
    its(:name) { should == :Foo }
    its(:arguments) { should == [ast("a"), ast("b")] }
    its(:receiver) { should == ast("42") }
    its(:proc_argument) { should be_nil }
    its(:block) { should == ast("[a, b] { a + b }") }
    its(:splat_argument) { should be_nil }
  end

  context "when a node followed by a constant followed by ! with arguments with a block that has arguments" do
    let(:node) { ast("42 Foo!(a, b) [a, b]: a + b") }
    its(:name) { should == :Foo! }
    its(:arguments) { should == [ast("a"), ast("b")] }
    its(:receiver) { should == ast("42") }
    its(:proc_argument) { should be_nil }
    its(:block) { should == ast("[a, b] { a + b }") }
    its(:splat_argument) { should be_nil }
  end

  context "when a node followed by a constant followed by ? with arguments with a block that has arguments" do
    let(:node) { ast("42 Foo?(a, b) [a, b]: a + b") }
    its(:name) { should == :Foo? }
    its(:arguments) { should == [ast("a"), ast("b")] }
    its(:receiver) { should == ast("42") }
    its(:proc_argument) { should be_nil }
    its(:block) { should == ast("[a, b] { a + b }") }
    its(:splat_argument) { should be_nil }
  end
end
