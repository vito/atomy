require "spec_helper"

require "atomy/codeloader"

describe "core kernel" do
  subject { Atomy::Module.new { use(require_kernel("core")) } }

  it "implements do: notation for evaluating sequences" do
    expect(subject).to receive(:foo).and_return(1)
    expect(subject).to receive(:bar).and_return(2)
    expect(subject.evaluate(ast("do: foo, bar"), subject.compile_context)).to eq(2)
  end

  it "implements a macro-defining macro" do
    subject.evaluate(ast("macro(1): '2"), subject.compile_context)
    expect(subject.evaluate(ast("1"))).to eq(2)
  end

  it "implements sending messages to receivers" do
    expect(subject.evaluate(ast("1 inspect"))).to eq("1")
  end

  it "implements sending messages to receivers, with arguments" do
    expect(subject.evaluate(ast("128 to-s(16)"))).to eq("80")
  end

  it "implements sending messages to receivers, with blocks" do
    expect(subject.evaluate(ast("[1, 2, 3] collect [x]: x + 1"))).to eq([2, 3, 4])
  end

  it "implements sending messages to receivers, with arguments and blocks" do
    expect(subject.evaluate(ast("[1, 2, 3] inject(3) [a, b]: a + b"))).to eq(9)
  end

  it "implements nested constant notation" do
    expect(subject.evaluate(ast("Atomy Module"))).to eq(Atomy::Module)
  end

  describe "method definition" do
    it "implements method definition notation" do
      subject.evaluate(ast("def(foo(a)): a + 1"), subject.compile_context)
      expect(subject.foo(41)).to eq(42)
    end

    it "defines branches that close over its scope" do
      subject.evaluate(seq("a = 1, def(foo(b)): a + b"), subject.compile_context)
      expect(subject.foo(41)).to eq(42)
    end
  end

  describe "assignment" do
    it "implements local variable assignment notation" do
      expect(subject.evaluate(seq("a = 1, a + 2"))).to eq(3)
    end

    it "raises an error when the patterns don't match" do
      expect {
        subject.evaluate(ast("2 = 1"))
      }.to raise_error(Atomy::PatternMismatch)
    end
  end

  describe "blocks" do
    it "implements block literals" do
      blk = subject.evaluate(ast("[a, b]: a + b"))
      expect(blk).to be_kind_of(Proc)
      expect(blk.call(1, 2)).to eq(3)
    end

    it "constructs blocks that close over their scope" do
      blk = subject.evaluate(seq("a = 1, [b]: a + b"))
      expect(blk).to be_kind_of(Proc)
      expect(blk.call(2)).to eq(3)
    end

    it "pattern-matches block arguments" do
      blk = subject.evaluate(seq("[a, `(1 + ~b)]: [a, b value]"))
      expect(blk).to be_kind_of(Proc)
      expect(blk.call(1, ast("1 + 2"))).to eq([1, 2])
    end
  end
end
